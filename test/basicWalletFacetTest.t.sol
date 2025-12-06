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
import { IDiamondCut } from "../src/interfaces/IDiamondCut.sol";

contract BasicWalletFacetTest is Test {
    DiamondFactory factory;

    DiamondCutFacet cutFacet;
    DiamondLoupeFacet loupeFacet;
    OwnershipFacet ownershipFacet;
    ValidationFacet validationFacet;
    OwnerValidationFacet ownerValidatorFacet;
    BasicWalletFacet walletFacet;
    IDiamondCut diamond;

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

        // Deploy wallet facet under test
        walletFacet = new BasicWalletFacet();

        // Deploy DiamondFactory with required base facets
        factory = new DiamondFactory(
            address(cutFacet),
            address(loupeFacet),
            address(ownershipFacet),
            address(validationFacet),
            address(ownerValidatorFacet)
        );
        
        vm.stopPrank();

        vm.startPrank(user);

        address diamondAddr = factory.deployDiamond(1);
        diamond = IDiamondCut(diamondAddr);
        installFacetForTesting();

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
}
