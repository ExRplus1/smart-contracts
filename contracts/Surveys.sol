// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./NFTCreator.sol";

contract Surveys {
    // For the moment the OperatorAccountAddress in Localnet is 0.0.1000
    event Response(bool send, bytes data);
    address operatorAccountAddress;
    address nftContractAddress;

    constructor (address _operatorAccountAddress, address _nftContractAddress) {
        operatorAccountAddress =  _operatorAccountAddress;
        nftContractAddress = _nftContractAddress;
    }

    // Create hash out of 2 bytes32
    function createHash(bytes32 _a, bytes32 _b) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_a, _b));
    }

    /* Surveys */

    struct Survey {
        bytes32 surveyHash;
        address author;
    }

    // mapping(uint => Survey) surveys;
    // uint private surveysSize;

    Survey[] surveys;


    function setSurvey(bytes32 _surveyHash) public payable returns (bool) {
        // pay to create the survey
        // require(msg.value == _surveyCreationValue, "Insufficient funds for create this survey!");
        (bool send, bytes memory data )= operatorAccountAddress.call{value: msg.value}("");
        require(send, "Failed to pay the survey!");
        emit Response(send, data);
    
        //write surveyHash in blockchain
        // surveys[surveysSize+1] = Survey(_surveyHash, msg.sender);
        surveys.push(Survey(_surveyHash, msg.sender));
        // surveysSize++;
    
        return true;
    }

    function getSurvey(uint _i) public view returns (Survey memory) {
        return surveys[_i];
    }

    function getSurveys() public view returns (Survey[] memory) {
        // Survey[] memory values = new Survey[](surveysSize);

        // for (uint i = 0; i < surveysSize; i++) {
        //     values[i] = surveys[i];
        // }

        // return values;

        return surveys;
    }
  
    function getAuthorSurveys() public view returns (Survey[] memory) {
        uint j;
        uint k;

        for (uint i = 0; i < surveys.length; i++) {
            if(surveys[i].author == msg.sender) {
                k++;
            }
        }

        Survey[] memory values = new Survey[](k);

        for(uint i = 0; i < surveys.length; i++) {
            if(surveys[i].author == msg.sender) {
                values[j] = surveys[i];
                j++;
            }
        }

        return values;
    }

    /* Answers */

    struct Answer {
        bytes32 surveyHash;
        bytes32 answerHash;
        address userAddress;
    }

    // mapping(uint => Answer) answers;
    // uint private answersSize;

    Answer[] answers; 

    mapping(address => address[]) private userAddressToBadges;
    mapping(address => int64[]) private userAddressToBadgesIds;

    function setAnswer(bytes32 _surveyHash, bytes32 _answerHash) external payable returns (bool)  {

        // check if survey exists
        // require(surveyExist(_surveyHash), "Survey does not exists!");

        // pay to the answer the survey
        (bool send, bytes memory data)= operatorAccountAddress.call{value: msg.value}("");
        require(send, "Failed to pay the answers!");

        // add answer hash in blockchain
        answers.push(Answer(_surveyHash, _answerHash, msg.sender));
        emit Response(send, data); // ???

        /* generate the NFT and send it to the user */

        /* 
        * !!! This function must be called at survey creation and the token saved in context!!!
        * Then when user will finish the survey will call mintNft with token and surveyHash + answerHash
        * Tokens can be created with maxSupply equl with surveys number of users
        */

        NFTCreator nft = new NFTCreator(operatorAccountAddress);

        //CREATE
        address token = nft.createNft(
            string("HashChange"),               // token name
            string("EXR1"),                     // token symbol
            string("simple memo"),   // a simple memo
            int64(2),                          // maxSupply = numbers of users
            int64(7000000)                     // Expiration: Needs to be between 6999999 and 8000001
        );

        // MINT
        // metadata from surveyHash and answerHash
        bytes[] memory answerHash = new bytes[](2);
        answerHash[0] = abi.encodePacked(_surveyHash);
        answerHash[1] = abi.encodePacked(_answerHash);

        int64 serial = nft.mintNft(token, answerHash);

        // TRANSFER
        address receiver = msg.sender;
        nft.transferNft(token, receiver, serial);

        userAddressToBadges[msg.sender].push(token);
        userAddressToBadgesIds[msg.sender].push(serial);
        return true;
    }

    function surveyExist (bytes32 _survey) private view returns (bool) {
        for (uint i; i< surveys.length;i++){
            if (surveys[i].surveyHash ==_survey )
            return true;
        }
        return false;
    }

    function getAnswer(uint i) public view returns (Answer memory) {
        return answers[i];
    }

    function getAnswers() public view returns (Answer[] memory) {
        Answer[] memory ans = new Answer[](answers.length);
        for(uint i = 0; i < answers.length; i++) {
            ans[i] = answers[i];
        }
        return ans;
    }
 
    function getUserAnswers() public view returns (Answer[] memory) {
        Answer[] memory values = new Answer[](answers.length);
        uint j;
        for(uint i = 0; i < answers.length; i++) {
            if(answers[i].userAddress == msg.sender) {
                values[j] = answers[i];
                j++;
            }
        }

        return values;
    }


     // get badges of the caller that are not burned  - used for User' Portfolio
    // function getBadgesOfAddress() public view returns (address[] memory) {
    //     address[] memory badges = userAddressToBadges[msg.sender];
    //     address[] memory filteredBadges = new address[](badges.length);
    //     uint256 filteredBadgesIndex = 0;
    //     for (uint256 i = 0; i < badges.length; i++) {
    //         if (
    //             badges[i].ownerOf(userAddressToBadgesIds[msg.sender][i]) ==
    //             msg.sender
    //         ) {
    //             filteredBadges[filteredBadgesIndex] = badges[i];
    //             filteredBadgesIndex++;
    //         }
    //     }
    //     return filteredBadges;
    // }
}