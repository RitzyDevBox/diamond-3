// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {Diamond} from "../src/Diamond.sol";
import {DiamondFactory} from "../src/DiamondFactory.sol";
import {NFTAuthorityResolver} from "../src/resolvers/NFTAuthorityResolver.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {ExecuteFacet} from "../src/facets/ExecuteFacet.sol";
import {ValidationFacet} from "../src/facets/ValidationFacet.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";
import {IValidationModule} from "../src/interfaces/IValidationModule.sol";
import {IERC165} from "../src/interfaces/IERC165.sol";
import { MockERC721 } from "./mocks/MockERC721.sol";

/// ------------------------------------------------------------
/// Mock Facet
/// ------------------------------------------------------------
contract MockFacet {
    event Ping(address caller);
    function ping() external { emit Ping(msg.sender); }
}

/// ------------------------------------------------------------
/// TEST FACTORY
/// ------------------------------------------------------------
contract NFTDiamondFactoryTest is Test {
    DiamondFactory factory;

    // Pre-deployed facet singletons
    DiamondCutFacet cutFacet;
    DiamondLoupeFacet loupeFacet;
    ValidationFacet validationFacet;
    NFTAuthorityResolver nftAuthorityResolver;
    MockFacet mockFacet;
    ExecuteFacet executeFacet;
    MockERC721 nft;

    uint256 constant TOKEN_ID = 1;
    address deployer = address(0xBEEF);
    address user     = address(0xCAFE);
    address otherUser = address(0xD00D);

    function setUp() public {
        vm.startPrank(deployer);

        // Deploy shared facets
        cutFacet = new DiamondCutFacet();
        loupeFacet = new DiamondLoupeFacet();
        validationFacet = new ValidationFacet();
        nftAuthorityResolver = new NFTAuthorityResolver(deployer);
        executeFacet = new ExecuteFacet();
        mockFacet = new MockFacet();

        // Deploy factory
        factory = new DiamondFactory(
            address(cutFacet),
            address(loupeFacet),
            address(validationFacet),
            address(executeFacet)
        );

        nftAuthorityResolver.setFactory(address(factory));
        nft = new MockERC721();
        nft.mint(user, TOKEN_ID);

        vm.stopPrank();


    }

    /// ------------------------------------------------------------
    /// MAIN TEST — deploy wallet + verify
    /// ------------------------------------------------------------
    function testDeployDiamondAndValidate() public {
        vm.startPrank(user);

        // Deploy new diamond using seed=1
        address diamondAddr = factory.deployDiamond(address(nftAuthorityResolver), abi.encode(address(nft), TOKEN_ID));

        // --------------- ASSERT CALL ALLOWED (owner) ------

        installMockFacet(IDiamondCut(diamondAddr));
        
        
        vm.expectEmit(true, false, false, true);
        emit MockFacet.Ping(user);

        // Should succeed because user == owner
        MockFacet(diamondAddr).ping();

        vm.stopPrank();
    }

    /// ------------------------------------------------------------
    /// Test validator blocks non-owner
    /// ------------------------------------------------------------
    function testValidatorBlocksNonOwner() public {
        vm.startPrank(user);

        address diamondAddr = factory.deployDiamond(address(nftAuthorityResolver), abi.encode(address(nft), TOKEN_ID));
        installMockFacet(IDiamondCut(diamondAddr));
        vm.stopPrank();

        // Non-owner
        vm.startPrank(address(0xBAD));

        vm.expectRevert(Diamond.NotAuthorized.selector);
        MockFacet(diamondAddr).ping();

        vm.stopPrank();
    }

    function testPublicSelectorsArePublic() public {
        vm.startPrank(user);

        // Deploy diamond
        address diamondAddr = factory.deployDiamond(address(nftAuthorityResolver), abi.encode(address(nft), TOKEN_ID));

        vm.stopPrank();

        // Now ANYONE should be able to call public selectors
        vm.startPrank(address(0xB0B));

        // --- facets() ---
        IDiamondLoupe.Facet[] memory f = IDiamondLoupe(diamondAddr).facets();
        assertGt(f.length, 0, "facets should be public");

        // --- facetAddresses() ---
        address[] memory addrs = IDiamondLoupe(diamondAddr).facetAddresses();
        assertGt(addrs.length, 0, "facetAddresses should be public");

        // --- facetFunctionSelectors() ---
        bytes4[] memory selectors = IDiamondLoupe(diamondAddr).facetFunctionSelectors(addrs[0]);
        assertGt(selectors.length, 0, "facetFunctionSelectors should be public");

        // --- facetAddress() ---
        address addr = IDiamondLoupe(diamondAddr).facetAddress(selectors[0]);
        assertTrue(addr != address(0), "facetAddress should be public");

        vm.stopPrank();
    }

    function testNFTTransferUpdatesAuthority() public {
        vm.startPrank(user);

        address diamondAddr = factory.deployDiamond(
            address(nftAuthorityResolver),
            abi.encode(address(nft), TOKEN_ID)
        );

        installMockFacet(IDiamondCut(diamondAddr));

        // user is initial NFT owner → allowed
        MockFacet(diamondAddr).ping();

        vm.stopPrank();

        // transfer NFT
        nft.transferFrom(user, otherUser, TOKEN_ID);

        // old owner blocked
        vm.startPrank(user);
        vm.expectRevert(Diamond.NotAuthorized.selector);
        MockFacet(diamondAddr).ping();
        vm.stopPrank();

        // new NFT owner allowed
        vm.startPrank(otherUser);
        vm.expectEmit(true, false, false, true);
        emit MockFacet.Ping(otherUser);
        MockFacet(diamondAddr).ping();
        vm.stopPrank();
    }



    function installMockFacet(IDiamondCut diamond) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mockFacetSelectors()
        });

        diamond.diamondCut(cut, address(0), "");
    }

    function mockFacetSelectors() internal pure returns (bytes4[] memory s) {
        s = new bytes4[](1);
        s[0] = MockFacet.ping.selector;
    }
}
