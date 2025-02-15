// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.6.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IRarity.sol";

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

contract TheRarityForest is ERC721 {

    using Counters for Counters.Counter;
    using Strings for uint256;

    constructor(address _rarityAddr) ERC721("TheRarityForest", "TRF") {
        rarityContract = IRarity(_rarityAddr);
    }

    uint256 private globalSeed;
    IRarity public rarityContract;
    mapping(address => mapping(uint256 => Research)) researchs;
    mapping(uint256 => string) items;
    mapping(uint256 => uint256) magic;
    mapping(uint256 => uint256) level;
    Counters.Counter public _tokenIdCounter;

    string[] sevenDaysItems = [
        "Dead King crown", 
        "Black gauntlet",
        "Haunted ring",
        "Ancient book",
        "Enchanted book",
        "Gold ring",
        "Treasure map",
        "Spell book",
        "Silver sword",
        "Ancient Prince Andre's Sword",
        "Old damaged coin",
        "Magic necklace",
        "Mechanical hand"
    ];
    string[] sixDaysItems = [
        "Silver sword",
        "Haunted ring",
        "War helmet",
        "Fire boots",
        "War trophy",
        "Elf skull",
        "Unknown ring",
        "Silver ring",
        "War book",
        "Gold pot",
        "Demon head",
        "Unknown key",
        "Cursed book",
        "Giant plant seed",
        "Old farmer sickle",
        "War trophy",
        "Enchanted useless tool"
    ];
    string[] fiveDaysItems = [
        "Dragon egg",
        "Bear claw",
        "Silver sword",
        "Rare ring",
        "Glove with diamonds",
        "Haunted cloak",
        "Dead hero cape",
        "Cursed talisman",
        "Enchanted talisman",
        "Haunted ring",
        "Time crystal",
        "Warrior watch",
        "Paladin eye",
        "Metal horse saddle",
        "Witcher book",
        "Witch book",
        "Unknown animal eye"
    ];
    string[] fourDaysItems = [
        "Slain warrior armor",
        "Witcher book",
        "Cursed talisman",
        "Antique ring",
        "Ancient Prince Andre's Sword",
        "King's son sword",
        "Old damaged coin",
        "Thunder hammer",
        "Time crystal",
        "Skull fragment",
        "Hawk eye",
        "Meteorite fragment",
        "Mutant fisheye",
        "Wolf necklace",
        "Shadowy rabbit paw",
        "Paladin eye"
    ];

    event ResearchStarted(uint256 summonerId, address owner);
    event TreasureDiscovered(address owner, uint256 treasureId);
    event TreasureLevelUp(uint256 treasureId, uint256 summonerId, uint256 newLevel);

    struct Research {
        uint256 timeInDays;
        uint256 initBlock; //Block when research started
        bool discovered;
        uint256 summonerId;
        address owner;
    }

    //Gen random
    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    //Return required XP to levelup a treasure
    function xpRequired(uint currentLevel) public pure returns (uint xpToNextLevel) {
        xpToNextLevel = currentLevel * 1000e18;
        for (uint i = 1; i < currentLevel; i++) {
            xpToNextLevel += currentLevel * 1000e18;
        }
    }

    //Get random treasure
    function _randomTreasure(Research memory research) internal returns (string memory, uint256, uint256){
        string memory _string = string(abi.encodePacked(research.summonerId, abi.encodePacked(research.owner), abi.encodePacked(research.initBlock), abi.encodePacked(globalSeed)));
        uint256 index = _random(_string);
        globalSeed = index;

        if (research.timeInDays == 7) {
            //(itemName, magic, level)
            return (sevenDaysItems[index % sevenDaysItems.length], index % 11, index % 6);
        }
        if (research.timeInDays == 6) {
            //(itemName, magic, level)
            return (sixDaysItems[index % sixDaysItems.length], index % 11, index % 6);
        }
        if (research.timeInDays == 5) {
            //(itemName, magic, level)
            return (fiveDaysItems[index % fiveDaysItems.length], index % 11, index % 6);
        }
        if (research.timeInDays == 4) {
            //(itemName, magic, level)
            return (fourDaysItems[index % fourDaysItems.length], index % 11, index % 6);
        }
        
    }

    //Is owner of summoner or is approved
    function _isApprovedOrOwnerOfSummoner(uint256 summonerId, address _owner) internal view virtual returns (bool) {
        //_owner => expected owner
        address spender = address(this);
        address owner = rarityContract.ownerOf(summonerId);
        return (owner == _owner || rarityContract.getApproved(summonerId) == spender || rarityContract.isApprovedForAll(owner, spender));
    }

    //Mint a new ERC721
    function safeMint(address to) internal returns (uint256){
        uint256 counter = _tokenIdCounter.current();
        _safeMint(to, counter);
        _tokenIdCounter.increment();
        return counter;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[7] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = string(abi.encodePacked("name", " ", items[tokenId]));

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = string(abi.encodePacked("magic", " ", magic[tokenId].toString()));

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = string(abi.encodePacked("level", " ", level[tokenId].toString()));

        parts[6] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "treasure #', tokenId.toString(), '", "description": "Rarity is achieved through good luck and intelligence", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    //Research for new treasuries
    function startResearch(uint256 summonerId, uint256 timeInDays) public returns (uint256) {
        //timeInDays -> time to research the forest
        require(timeInDays >= 4 && timeInDays <= 7, "not valid");
        require(_isApprovedOrOwnerOfSummoner(summonerId, msg.sender), "not your summoner");
        (,,,uint256 summonerLevel) = rarityContract.summoner(summonerId);
        require(summonerLevel >= 2, "not level >= 2");
        require(researchs[msg.sender][summonerId].timeInDays == 0 || researchs[msg.sender][summonerId].discovered == true, "not empty or not discovered yet"); //If empty or already discovered
        researchs[msg.sender][summonerId] = Research(timeInDays, block.timestamp, false, summonerId, msg.sender);
        emit ResearchStarted(summonerId, msg.sender);
        return summonerId;
    }

    //Discover a treasure
    function discover(uint256 summonerId) public returns (uint256){
        Research memory research = researchs[msg.sender][summonerId];
        require(!research.discovered && research.timeInDays > 0, "already discovered or not initialized");
        require(research.initBlock + (research.timeInDays * 1 days) < block.timestamp, "not finish yet");
        //mint erc721 based on pseudo random things
        (string memory _itemName, uint256 _magic, uint256 _level) = _randomTreasure(research);
        uint256 newTokenId = safeMint(msg.sender);
        items[newTokenId] = _itemName;
        magic[newTokenId] = _magic;
        level[newTokenId] = _level;
        research.discovered = true;
        researchs[msg.sender][summonerId] = research;
        emit TreasureDiscovered(msg.sender, newTokenId);
        return newTokenId;
    }

    //Level up an item, spending summoner XP (need approval)
    function levelUp(uint256 summonerId, uint256 tokenId) public {
        require(_isApprovedOrOwnerOfSummoner(summonerId, msg.sender), "not your treasure");
        uint256 current = level[tokenId];
        rarityContract.spend_xp(summonerId, xpRequired(current));
        level[tokenId] += 1;
        emit TreasureLevelUp(tokenId, summonerId, current + 1);
    }

    //View your treasure
    function treasure(uint tokenId) external view returns (string memory _itemName, uint _magic, uint _level) {
        _itemName = items[tokenId];
        _magic = magic[tokenId];
        _level = level[tokenId];
    }

}