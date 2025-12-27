// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import { DiamondFactory } from "../src/DiamondFactory.sol";
import { DiamondCutFacet } from "../src/facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "../src/facets/DiamondLoupeFacet.sol";
import { ValidationFacet } from "../src/facets/ValidationFacet.sol";
import { OwnerAuthorityResolver } from "../src/resolvers/OwnerAuthorityResolver.sol";

import { ExecuteFacet } from "../src/facets/ExecuteFacet.sol";
import { IDiamondCut } from "../src/interfaces/IDiamondCut.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";
import { MockERC721 } from "./mocks/MockERC721.sol";
import { MockWETH } from "./mocks/MockWETH.sol";

contract ExecuteFacetTest is Test {
    DiamondFactory factory;

    DiamondCutFacet cutFacet;
    DiamondLoupeFacet loupeFacet;
    ValidationFacet validationFacet;
    OwnerAuthorityResolver ownerAuthorityResolver;
    ExecuteFacet executeFacet;
    address diamondAddr;

    ExecuteFacet diamondExec;

    address deployer = address(0xBEEF);
    address user = address(0xCAFE);

    function setUp() public {
        vm.startPrank(deployer);

        // Deploy core facets
        cutFacet = new DiamondCutFacet();
        loupeFacet = new DiamondLoupeFacet();
        validationFacet = new ValidationFacet();
        ownerAuthorityResolver = new OwnerAuthorityResolver(deployer);
        executeFacet = new ExecuteFacet();


        // Deploy DiamondFactory with required base facets
        factory = new DiamondFactory(
            address(cutFacet),
            address(loupeFacet),
            address(validationFacet),
            address(executeFacet)
        );
        
        ownerAuthorityResolver.setFactory(address(factory));

        vm.stopPrank();

        vm.startPrank(user);

        diamondAddr = factory.deployDiamond(address(ownerAuthorityResolver), abi.encode(user));

        diamondExec = ExecuteFacet(diamondAddr);
        vm.stopPrank();

    }


    /// ------------------------------------------------------------
    /// Facet Tests 
    /// ------------------------------------------------------------
    function testSendETH() public {
        vm.deal(diamondAddr, 5 ether);

        address recipient = address(0xBABE);
        uint256 beforeBal = recipient.balance;

        vm.prank(user);
        diamondExec.execute(recipient, 1 ether, "");

        assertEq(recipient.balance, beforeBal + 1 ether);
        assertEq(diamondAddr.balance, 4 ether);
    }

    function testWrapAndUnwrapETH() public {
        MockWETH weth = new MockWETH();
        vm.deal(diamondAddr, 2 ether);

        bytes memory wrapData = abi.encodeWithSelector(MockWETH.deposit.selector);

        vm.prank(user);
        diamondExec.execute(address(weth), 1 ether, wrapData);
        assertEq(weth.balanceOf(diamondAddr), 1 ether);

        bytes memory unwrapData =
            abi.encodeWithSelector(MockWETH.withdraw.selector, 1 ether);

        vm.prank(user);
        diamondExec.execute(address(weth), 0, unwrapData);

        assertEq(weth.balanceOf(diamondAddr), 0);
        assertEq(diamondAddr.balance, 2 ether);
    }

    function testSendERC20() public {
        MockERC20 token = new MockERC20();
        token.mint(diamondAddr, 500);

        bytes memory data = abi.encodeWithSelector(
            MockERC20.transfer.selector,
            address(0xF00D),
            100
        );

        vm.prank(user);
        diamondExec.execute(address(token), 0, data);

        assertEq(token.balanceOf(address(0xF00D)), 100);
        assertEq(token.balanceOf(diamondAddr), 400);
    }

    function testApproveERC20() public {
        MockERC20 token = new MockERC20();

        bytes memory data = abi.encodeWithSelector(
            MockERC20.approve.selector,
            address(0xF00D),
            123
        );

        vm.prank(user);
        diamondExec.execute(address(token), 0, data);

        assertEq(token.allowance(diamondAddr, address(0xF00D)), 123);
    }

    function testSendERC721() public {
        MockERC721 nft = new MockERC721();
        nft.mint(diamondAddr, 77);

        bytes memory data = abi.encodeWithSelector(
            bytes4(keccak256("safeTransferFrom(address,address,uint256)")), 
            diamondAddr,
            address(0xC0FFEE),
            77
        );

        vm.prank(user);
        diamondExec.execute(address(nft), 0, data);

        assertEq(nft.ownerOf(77), address(0xC0FFEE));
    }

    function testApproveERC721() public {
        MockERC721 nft = new MockERC721();
        nft.mint(diamondAddr, 88);

        bytes memory data = abi.encodeWithSelector(
            MockERC721.approve.selector,
            address(0xF00D),
            88
        );

        vm.prank(user);
        diamondExec.execute(address(nft), 0, data);

        assertEq(nft.getApproved(88), address(0xF00D));
    }

    function testSetERC721ApprovalForAll() public {
        MockERC721 nft = new MockERC721();

        bytes memory data = abi.encodeWithSelector(
            MockERC721.setApprovalForAll.selector,
            address(0xF00D),
            true
        );

        vm.prank(user);
        diamondExec.execute(address(nft), 0, data);

        assertTrue(nft.isApprovedForAll(diamondAddr, address(0xF00D)));
    }

    function testBatchExecute() public {
        // Setup: token + NFT
        MockERC20 token = new MockERC20();
        MockERC721 nft = new MockERC721();

        // Fund/setup balances
        token.mint(diamondAddr, 500);
        nft.mint(diamondAddr, 777);

        ExecuteFacet.ExecCall[] memory calls = new ExecuteFacet.ExecCall[](2);


        // 1. ERC20 transfer 100 tokens → 0xF00D
        calls[0] = ExecuteFacet.ExecCall({
            to: address(token),
            value: 0,
            data: abi.encodeWithSelector(
                MockERC20.transfer.selector,
                address(0xF00D),
                100
            )
        });

        // 2. ERC721 transfer tokenId 777 → 0xC0FFEE
        calls[1] = ExecuteFacet.ExecCall({
            to: address(nft),
            value: 0,
            data: abi.encodeWithSelector(
                bytes4(keccak256("safeTransferFrom(address,address,uint256)")),
                diamondAddr,
                address(0xC0FFEE),
                777
            )
        });

        // --- Execute batch ---
        vm.prank(user);
        diamondExec.batchExecute(calls);

        // --- Assertions ---
        assertEq(token.balanceOf(address(0xF00D)), 100, "ERC20 not transferred");
        assertEq(token.balanceOf(diamondAddr), 400, "ERC20 balance mismatch");

        assertEq(nft.ownerOf(777), address(0xC0FFEE), "ERC721 not transferred");
    }
}
