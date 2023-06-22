// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./HederaResponseCodes.sol";
import "./IHederaTokenService.sol";
import "./HederaTokenService.sol";
import "./ExpiryHelper.sol";
import "./KeyHelper.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Surveys is ExpiryHelper, KeyHelper, HederaTokenService {
    
    event Response(bool send, bytes data);
    address operatorAccountAddress;
    constructor (address _operatorAccountAddresss) {
        operatorAccountAddress = _operatorAccountAddresss;
    }

    mapping(address => uint) Balance;

    // Create hash out of 2 bytes32
    function createHash(bytes32 _a, bytes32 _b) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_a, _b));
    }

    /* Surveys */

    struct Survey {
        bytes32 surveyHash;
        address author;
        address nftAddress;
    }

    Survey[] surveys;

    function setSurvey(bytes32 _surveyHash) external payable returns (bool) {
        Balance[msg.sender] += msg.value;
        // require(msg.value == _surveyCreationValue, "Insufficient funds for create this survey!");

        // (bool send, bytes memory data )= operatorAccountAddress.call{value: msg.value}("");
        // require(send, "Failed to pay the survey!");
    
        surveys.push(Survey(
            _surveyHash, 
            msg.sender,
            createNft(
                  string("HashChange"),           // token name
                  string("EXR1"),                 // token symbol
                  string("from surveys"),         // a simple memo
                  int64(10),                      // maxSupply = numbers of users
                  int64(7000000)                  // Expiration: Needs to be between 6999999 and 8000001
                )
            ));

        // emit Response(send, data);
        return true;
    }

    function getSurvey(uint _i) public view returns (Survey memory) {
        return surveys[_i];
    }

    function getSurveys() public view returns (Survey[] memory) {
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

    Answer[] answers; 

    mapping(address => address[]) private userAddressToBadges;
    mapping(address => int64[]) private userAddressToBadgesIds;

    function getNftAddressForSurveyHash(bytes32 surveyHash) private view returns (address) {
        address nftAddress;
        for (uint i = 0; i < surveys.length; i++) {
                if(surveys[i].surveyHash == surveyHash) {
                    nftAddress = surveys[i].nftAddress;
                }
        }
        return nftAddress;
    }

    function setAnswer(bytes32 _surveyHash, bytes32 _answerHash, bytes[] memory _metadata) external payable returns (int64)  {

        Balance[msg.sender] += msg.value;

        address nftAddress = getNftAddressForSurveyHash(_surveyHash);
        // check if survey exists
        // require(surveyExist(_surveyHash), "Survey does not exists!");

        // pay to the answer the survey
        // (bool send, bytes memory data)= operatorAccountAddress.call{value: msg.value}("");
        // require(send, "Failed to pay the answers!");

        answers.push(Answer(_surveyHash, _answerHash, msg.sender));

        // MINT
        int64 serial = mintNft(nftAddress, _metadata);

        // TRANSFER
        uint serial256 = uint256(uint64(serial));
        IERC721(nftAddress).approve(msg.sender, serial256);
        IERC721(nftAddress).transferFrom(address(this), msg.sender, serial256);

        userAddressToBadges[msg.sender].push(nftAddress);
        userAddressToBadgesIds[msg.sender].push(serial);

        // emit Response(send, data);

        return serial; //we should export the nft address and mint' serial and call the transfer function with its
    }

    // check if survey exists
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

    function getBalance() public view returns (uint) {
        return address(this).balance;
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

   function createNft(
            string memory name, 
            string memory symbol, 
            string memory memo, 
            int64 maxSupply,  
            int64 autoRenewPeriod
        ) public payable returns (address){

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](7);
        keys[0] = getSingleKey(KeyType.ADMIN, KeyValueType.CONTRACT_ID, address(this));
        keys[1] = getSingleKey(KeyType.SUPPLY, KeyValueType.CONTRACT_ID, address(this));
        keys[2] = getSingleKey(KeyType.FREEZE, KeyValueType.CONTRACT_ID, address(this));
        keys[3] = getSingleKey(KeyType.FEE, KeyValueType.CONTRACT_ID, address(this));
        keys[4] = getSingleKey(KeyType.KYC, KeyValueType.CONTRACT_ID, address(this));
        keys[5] = getSingleKey(KeyType.PAUSE, KeyValueType.CONTRACT_ID, address(this));
        keys[6] = getSingleKey(KeyType.WIPE, KeyValueType.CONTRACT_ID, address(this));

        IHederaTokenService.HederaToken memory token;
        token.name = name;
        token.symbol = symbol;
        token.memo = memo;
        token.treasury = address(this);
        token.tokenSupplyType = true; // set supply to FINITE
        token.maxSupply = maxSupply;
        token.tokenKeys = keys;
        token.freezeDefault = false;
        token.expiry = createAutoRenewExpiry(address(this), autoRenewPeriod); // Contract auto-renews the token

        (int responseCode, address createdToken) = HederaTokenService.createNonFungibleToken(token);

        if(responseCode != HederaResponseCodes.SUCCESS){
            revert("Failed to create non-fungible token");
        }
        return createdToken;
    }

    function mintNft(
        address token,
        bytes[] memory metadata
    ) public payable returns(int64){
        (int response, , int64[] memory serial) = HederaTokenService.mintToken(token, 0, metadata);
        if(response != HederaResponseCodes.SUCCESS){
            revert("Failed to mint non-fungible token");
        }
        return serial[0];
    }

    // function transferNft(
    //     address _token,
    //     int64 _serial
    // ) public payable returns(int){
      
    //     int response = HederaTokenService.transferNFT(_token, address(this), address(msg.sender), _serial);
    //     if(response != HederaResponseCodes.SUCCESS){
    //         revert("Failed to transfer non-fungible token");
    //     }
    //     return response;
    // }

     function approveNft(
        address _token, 
        uint256 _serialNumber
    ) public returns (int responseCode) {
          HederaTokenService.associateToken(
            address(msg.sender),
            _token
        );

        responseCode = HederaTokenService.approveNFT(_token, msg.sender, _serialNumber);
        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert ("Failed to approve non-fungibile token");
        }
        return responseCode;
    }


/// play ground

    // function approveNft(address token, uint256 tokenId) external payable {
    //     IERC721(token).approve(msg.sender, tokenId);
    // }

    //The call will be executed by the contract itself, so the contract address has to be the owner of `tokenId`
    function transferNft(address token, uint256 tokenId) external payable {

        IERC721(token).transferFrom(address(this), msg.sender, tokenId);
       
        //    ERROR_DECODING_PRECOMPILE_INPUT
        // IERC721(token).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function  getApprovedNft(address token, uint256 tokenId) external view returns (address) {
        return IERC721(token).getApproved(tokenId);
    }

    function ownerOfNft(address token, uint256 tokenId) external view returns (address) {
        return IERC721(token).ownerOf(tokenId);
    }

    function nameOfNft(address token) public view returns (string memory) {
        return IERC721Metadata(token).name();
    }

    function symbolOfNft(address token) public view returns (string memory) {
        return IERC721Metadata(token).symbol();
    }

    function tokenURIOfNft(address token, uint256 tokenId) public view returns (string memory) {
        return IERC721Metadata(token).tokenURI(tokenId);
    }

    /** MSG:: PRECOMPILE ERROR  */
    /* ================== */

   // The `to` address will receive approval by msg.sender
    // function delegateApproveNft(address token, uint256 tokenId) external payable {
    //     address(IERC721(token)).delegatecall(abi.encodeWithSignature("approve(address,uint256)", operatorAccountAddress, tokenId));
    // }
    

   // The call will be executed by the msg.sender address
    // function delegateTransferFromNft(address token, uint256 tokenId) external payable {
    //     address(IERC721(token)).delegatecall(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), operatorAccountAddress, tokenId));
    // }



}