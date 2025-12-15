// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import { DiamondFactory } from "../src/DiamondFactory.sol";
import { DiamondCutFacet } from "../src/facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "../src/facets/DiamondLoupeFacet.sol";
import { OwnershipFacet } from "../src/facets/OwnershipFacet.sol";
import { ValidationFacet } from "../src/facets/ValidationFacet.sol";
import { OwnerValidationFacet } from "../src/facets/OwnerValidationFacet.sol";
import { BasicWalletFacet } from "../src/facets/BasicWalletFacet.sol";
import { ExecuteFacet } from "../src/facets/ExecuteFacet.sol";
import { IDiamondCut } from "../src/interfaces/IDiamondCut.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";
import { MockERC721 } from "./mocks/MockERC721.sol";
import { MockWETH } from "./mocks/MockWETH.sol";

contract BasicWalletFacetTest is Test {
    DiamondFactory factory;

    DiamondCutFacet cutFacet;
    DiamondLoupeFacet loupeFacet;
    OwnershipFacet ownershipFacet;
    ValidationFacet validationFacet;
    OwnerValidationFacet ownerValidatorFacet;
    BasicWalletFacet walletFacet;
    ExecuteFacet executeFacet;
    IDiamondCut diamond;
    BasicWalletFacet wallet;

    address deployer = address(0xBEEF);
    address user = address(0xCAFE);

    function setUp() public {
        vm.startPrank(deployer);

        // Deploy core facets
        cutFacet = new DiamondCutFacet();
        loupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        validationFacet = new ValidationFacet();
        ownerValidatorFacet = new OwnerValidationFacet();
        executeFacet = new ExecuteFacet();

        // Deploy wallet facet under test
        walletFacet = new BasicWalletFacet();

        // Deploy DiamondFactory with required base facets
        factory = new DiamondFactory(
            address(cutFacet),
            address(loupeFacet),
            address(ownershipFacet),
            address(validationFacet),
            address(ownerValidatorFacet),
            address(executeFacet)
        );
        
        vm.stopPrank();

        vm.startPrank(user);


        address diamondAddr = factory.deployDiamond(1);
        diamond = IDiamondCut(diamondAddr);
        installFacetForTesting();
        wallet = BasicWalletFacet(payable(address(diamond))); 

        bytes4[] memory arr = new bytes4[](1);
        arr[0] = BasicWalletFacet.onERC721Received.selector;
        ValidationFacet(address(diamond)).setPublicSelector(arr, true);

        vm.stopPrank();

    }

    function installFacetForTesting() public {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[]( 1 ) ;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(walletFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: installFacetSelectors()
        });

        diamond.diamondCut(cut, address(0), "");
    }

    function installFacetSelectors() internal pure returns (bytes4[] memory s) {
        s = new bytes4[](9);
        s[0] = BasicWalletFacet.sendETH.selector;
        s[1] = BasicWalletFacet.wrapETH.selector;
        s[2] = BasicWalletFacet.unwrapETH.selector;
        s[3] = BasicWalletFacet.sendERC20.selector;
        s[4] = BasicWalletFacet.approveERC20.selector;
        s[5] = BasicWalletFacet.sendERC721.selector;
        s[6] = BasicWalletFacet.approveERC721.selector;
        s[7] = BasicWalletFacet.setERC721ApprovalForAll.selector;
        s[8] = BasicWalletFacet.onERC721Received.selector;
    }


    /// ------------------------------------------------------------
    /// Facet Tests 
    /// ------------------------------------------------------------

    function testSendETH() public {

        // Fund the diamond
        vm.deal(address(diamond), 5 ether);

        address recipient = address(0xBABE);
        uint256 before = recipient.balance;

        vm.prank(user);
        wallet.sendETH(recipient, 1 ether);

        assertEq(recipient.balance, before + 1 ether, "ETH not sent");
        assertEq(address(diamond).balance, 4 ether, "Diamond balance incorrect");
    }

    function testWrapAndUnwrapETH() public {
        // deploy fake WETH
        MockWETH weth = new MockWETH();

        vm.deal(address(diamond), 2 ether);

        // wrap 1 ETH
        vm.prank(user);
        wallet.wrapETH(address(weth), 1 ether);
        assertEq(weth.balanceOf(address(diamond)), 1 ether, "WETH not minted");

        // unwrap 1 ETH
        vm.prank(user);
        wallet.unwrapETH(address(weth), 1 ether);
        assertEq(weth.balanceOf(address(diamond)), 0, "WETH not burned");
        assertEq(address(diamond).balance, 2 ether, "ETH not unwrapped");
    }

    function testSendERC20() public {
        MockERC20 token = new MockERC20();

        // give diamond 500 tokens
        token.mint(address(diamond), 500);

        vm.prank(user);
        wallet.sendERC20(address(token), address(0xF00D), 100);

        assertEq(token.balanceOf(address(0xF00D)), 100, "did not transfer");
        assertEq(token.balanceOf(address(diamond)), 400, "diamond balance wrong");
    }

    function testApproveERC20() public {
        MockERC20 token = new MockERC20();

        vm.prank(user);
        wallet.approveERC20(address(token), address(0xF00D), 123);

        assertEq(token.allowance(address(diamond), address(0xF00D)), 123);
    }

    function testSendERC721() public {
        MockERC721 nft = new MockERC721();

        // mint NFT to diamond
        nft.mint(address(diamond), 77);

        vm.prank(user);
        wallet.sendERC721(address(nft), address(0xC0FFEE), 77);

        assertEq(nft.ownerOf(77), address(0xC0FFEE));
    }

    function testApproveERC721() public {
        MockERC721 nft = new MockERC721();
        nft.mint(address(diamond), 88);

        vm.prank(user);
        wallet.approveERC721(address(nft), address(0xF00D), 88);

        assertEq(nft.getApproved(88), address(0xF00D));
    }

    function testSetERC721ApprovalForAll() public {
        MockERC721 nft = new MockERC721();

        vm.prank(user);
        wallet.setERC721ApprovalForAll(address(nft), address(0xF00D), true);

        assertTrue(nft.isApprovedForAll(address(diamond), address(0xF00D)));
    }

    //TODO: This test will fail until we update the validator to allow anyone to call the callback
    function testERC721Receiver() public {
        MockERC721 nft = new MockERC721();

        // safe transfer TO diamond
        nft.mint(address(this), 999);

        // trigger safeTransferFrom which calls onERC721Received
        nft.safeTransferFrom(address(this), address(diamond), 999);

        assertEq(nft.ownerOf(999), address(diamond), "diamond did not receive NFT");
    }
}
