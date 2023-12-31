// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Test } from "@std/Test.sol";
import { LibString } from "@solady/utils/LibString.sol";

import { AccessControlHelper } from "../helpers/AccessControlHelper.sol";
import { Constants } from "../helpers/Constants.sol";

import { Membership } from "../src/Membership.sol";

/// @title Test for {Membership}
/// @author Olivier Winkler (https://github.com/owieth)
/// @custom:security-contact xxx@gmail.com
contract MembershipTest is Test, AccessControlHelper, Constants {
    address private constant DEFAULT_ADMIN_ADDRESS = address(100);

    Membership public s_membership;

    function setUp() public {
        s_membership = new Membership(DEFAULT_ADMIN_ADDRESS, address(2));
    }

    function test_ShouldRevertMintIfAlreadyMember() public {
        uint256 _tokenId = s_membership.mint();
        assertEq(_tokenId, s_membership.totalSupply());

        vm.expectRevert(abi.encodeWithSignature("Membership__YouAlreadyAreMember()"));
        s_membership.mint();
    }

    function test_Mint() public {
        uint256 _tokenId = s_membership.mint();
        s_membership.tokenURI(_tokenId);
    }

    function test_ShouldRevertUpdateProfileImageUri() public {
        string memory _newUri = "https://image-uri.com";

        vm.prank(address(112_233));
        uint256 _tokenId = s_membership.mint();

        vm.expectRevert(abi.encodeWithSignature("Membership__YouDontOwnThisMembership(uint256)", _tokenId));
        s_membership.updateProfileImageUri(_tokenId, _newUri);
    }

    function test_UpdateProfileImageUri() public {
        string memory _newUri = "https://image-uri.com";

        uint256 _tokenId = s_membership.mint();

        s_membership.updateProfileImageUri(_tokenId, _newUri);

        assertEq(_newUri, s_membership.getTokenStructById(_tokenId).profileImageUri);
    }

    function test_ShouldRevertIncreaseEventAttendanceIfNotAdmin() public {
        uint256 _tokenId = s_membership.mint();

        assertEq(s_membership.getTokenStructById(_tokenId).attendedEvents, 1);

        vm.prank(DEFAULT_SENDER);
        vm.expectRevert(getAccessControlRevertMessage(DEFAULT_SENDER, vm.toString(DEFAULT_ADMIN_ROLE)));
        s_membership.increaseEventAttendance(_tokenId);
    }

    function test_IncreaseEventAttendanceIfNotAdmin() public {
        uint256 _tokenId = s_membership.mint();

        assertEq(s_membership.getTokenStructById(_tokenId).attendedEvents, 1);

        vm.prank(DEFAULT_ADMIN_ADDRESS);
        s_membership.increaseEventAttendance(_tokenId);

        assertEq(s_membership.getTokenStructById(_tokenId).attendedEvents, 2);
    }

    function test_ShouldRevertTokenURI() public {
        uint256 _tokenId = 100;

        vm.expectRevert(abi.encodeWithSignature("Membership__InvalidTokenId(uint256)", _tokenId));
        s_membership.tokenURI(_tokenId);
    }

    function test_TokenURI() public {
        uint256 _tokenId = s_membership.mint();

        assertFalse(LibString.eq(s_membership.tokenURI(_tokenId), string(abi.encodePacked(""))));
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function test_ShouldRevertSetAnimationTokenUriPrefix() public {
        vm.prank(DEFAULT_SENDER);
        vm.expectRevert(getAccessControlRevertMessage(DEFAULT_SENDER, vm.toString(DEFAULT_ADMIN_ROLE)));
        s_membership.setAnimationTokenUriPrefix("");
    }

    function test_SetAnimationTokenUriPrefix() public {
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        s_membership.setAnimationTokenUriPrefix("");
    }

    function test_Upgrade() public {
        uint256 _tokenId = s_membership.mint();
        s_membership.tokenURI(_tokenId);

        vm.prank(DEFAULT_ADMIN_ADDRESS);
        s_membership.updateMembership(_tokenId, 100, 50);

        s_membership.tokenURI(_tokenId);
    }
}
