// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Ownable } from "@oz/access/Ownable.sol";
import { AccessControl } from "@oz/access/AccessControl.sol";
import { Counters } from "@oz/utils/Counters.sol";
import { ERC721 } from "@oz/token/ERC721/ERC721.sol";
import { ERC721URIStorage } from "@oz/token/ERC721/extensions/ERC721URIStorage.sol";
import { ERC721Enumerable } from "@oz/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC721Pausable } from "@oz/token/ERC721/extensions/ERC721Pausable.sol";
import { ERC721Burnable } from "@oz/token/ERC721/extensions/ERC721Burnable.sol";
import { Base64 } from "@oz/utils/Base64.sol";
import { Strings } from "@oz/utils/Strings.sol";

import { MembershipMetadata } from "./libraries/MembershipMetadata.sol";

/// @title Membership
/// @author https://swissdao.space/ (https://github.com/swissDAO)
/// @notice Membership Contract for swissDAO
/// @custom:security-contact dev@swissdao.space
contract Membership is Ownable, AccessControl, ERC721URIStorage, ERC721Enumerable, ERC721Pausable, ERC721Burnable {
    using Counters for Counters.Counter;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Explain to a developer any extra details
    bytes32 public constant CORE_DELEGATE_ROLE = keccak256("CORE_DELEGATE_ROLE");

    /// @notice Explain to a developer any extra details
    bytes32 public constant COMMUNITY_MANAGER_ROLE = keccak256("COMMUNITY_MANAGER_ROLE");

    /// @notice Explain to a developer any extra details
    bytes32 public constant EVENT_MANAGER_ROLE = keccak256("EVENT_MANAGER_ROLE");

    /// @notice Explain to a developer any extra details
    bytes32 public constant PROJECT_MANAGER_ROLE = keccak256("PROJECT_MANAGER_ROLE");

    /// @notice Explain to a developer any extra details
    bytes32 public constant TREASURY_MANAGER_ROLE = keccak256("TREASURY_MANAGER_ROLE");

    /// @notice Explain to a developer any extra details
    bytes32 public constant DEVELOPER_ROLE = keccak256("DEVELOPER_ROLE");

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Struct that contains vital information
    ///      timestamp: Minted Timestamp
    struct TokenStruct {
        uint256 mintedAt;
        uint256 joinedAt;
        uint256 experiencePoints;
        uint256 activityPoints;
        address holder;
        TokenState state;
    }

    /*//////////////////////////////////////////////////////////////
                                ENUMS
    //////////////////////////////////////////////////////////////*/

    enum TokenState {
        ONBOARDING,
        ACTIVE,
        INACTIVE,
        LABS
    }

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Tracker of tokenIds
    Counters.Counter private s_tokenIds;

    /// @dev Track of all swissDAO Memberships
    mapping(uint256 _tokenId => TokenStruct _membership) private s_memberships;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize NFTIME Contract, grant DEFAULT_ADMIN_ROLE to multisig
    /// @param _defaultAdminRoler New DefaultAdminRoler address
    /// @param _coreDelegateRoler New CoreDelegateRoler address
    constructor(address _defaultAdminRoler, address _coreDelegateRoler) ERC721("Membership", "MEMBER") {
        _setRoleAdmin(CORE_DELEGATE_ROLE, DEFAULT_ADMIN_ROLE); // Only the swissDAO multisig wallet can grant the core delegate role/guild.
        _setRoleAdmin(COMMUNITY_MANAGER_ROLE, CORE_DELEGATE_ROLE); // Only core delegates can assign roles/guilds.
        _setRoleAdmin(EVENT_MANAGER_ROLE, CORE_DELEGATE_ROLE); // Only core delegates can assign roles/guilds.
        _setRoleAdmin(PROJECT_MANAGER_ROLE, CORE_DELEGATE_ROLE); // Only core delegates can assign roles/guilds.
        _setRoleAdmin(TREASURY_MANAGER_ROLE, CORE_DELEGATE_ROLE); // Only core delegates can assign roles/guilds.
        _setRoleAdmin(DEVELOPER_ROLE, CORE_DELEGATE_ROLE); // Only core delegates can assign roles/guilds.

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdminRoler); // swissDAO mutlisig wallet address
        _grantRole(CORE_DELEGATE_ROLE, _coreDelegateRoler); // swissDAO mutlisig wallet address
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint Membership
    /// @return Returns new tokenId
    function mint() external payable whenNotPaused returns (uint256) {
        s_tokenIds.increment();
        uint256 _newItemId = s_tokenIds.current();

        _mint(msg.sender, _newItemId);

        s_memberships[_newItemId] = TokenStruct({
            mintedAt: block.timestamp,
            joinedAt: 0,
            experiencePoints: 0,
            activityPoints: 0,
            holder: msg.sender,
            state: TokenState.ONBOARDING
        });

        return _newItemId;
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Update Membership
    /// @param _tokenId Id of Membership
    /// @param _tokenStruct New values for Membership
    function updateMembership(
        uint256 _tokenId,
        TokenStruct memory _tokenStruct
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        s_memberships[_tokenId] = TokenStruct({
            mintedAt: _tokenStruct.mintedAt,
            joinedAt: _tokenStruct.joinedAt,
            experiencePoints: _tokenStruct.experiencePoints,
            activityPoints: _tokenStruct.activityPoints,
            holder: _tokenStruct.holder,
            state: _tokenStruct.state
        });
    }

    /// @notice Update DEFAULT_ADMIN_ROLE.
    /// @param _multisig New multisig address.
    function setDefaultAdminRole(address _multisig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, _multisig);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Update CORE_DELEGATE_ROLE.
    /// @param _multisig New multisig address.
    function setCoreDelegateRole(address _multisig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(CORE_DELEGATE_ROLE, _multisig);
        _revokeRole(CORE_DELEGATE_ROLE, msg.sender);
    }

    /// @notice Stop Minting
    function pauseTransactions() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Resume Minting
    function resumeTransactions() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                                PUBLIC
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                            INTERNAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @dev Override of the tokenURI function
    /// @param _tokenId TokenId
    /// @return Returns base64 encoded metadata
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        TokenStruct memory _tokenStruct = s_memberships[_tokenId];

        return MembershipMetadata.generateTokenURI(_tokenId, _tokenStruct);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    )
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /// @dev See {ERC721-_burn}.
    function _burn(uint256 _tokenId) internal override(ERC721, ERC721URIStorage) whenNotPaused {
        super._burn(_tokenId);
    }
}