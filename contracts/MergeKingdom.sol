//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ISilver.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract MergeKingdom is ERC721Enumerable, Ownable, Pausable {
    //
    //
    //  CODE STARTS HERE ☘️ 
    //
    //
    // SECTION VARIABLES _______________________________________________________________________________________________

    using Strings for uint256;

    string  public baseURI;
    string  public baseExtension = ".json";
    string  public notRevealedURI;
    //..
    uint    public totalFarmersMints;
    //..
    uint32  public totalMerges; 
    //..
    uint    public mintCost;
    uint    public wlMintCost;
    uint    public maxSupply = 100000;
    uint    public mintPerTx;
    uint    public mintPerWhitelist;
    uint    public rewardPerHour = 500;
    //..
    //..
    bool    public presale;
    bool    public revealed;
    //..
    uint    public baseFees   = 0.03 ether;
    uint    public baseMerge  = 100000;
    uint    public baseChance = 35;

    //!SECTION VARIABLES -----------------------------------------------------------------------------------------------
    //  
    //
    //
    // SECTION ARRAYS __________________________________________________________________________________________________

    // FARMER | KNIGHT | PRINCE | 

    uint32[] public tokenIds       = [0, 10000, 15000, 17500];
    uint32[] public priceModifier  = [100, 200, 300];           // +0%, +100%, +200%   
    uint  [] public feesModifier   = [100, 67, 50 ];            // -0%, -30%,  -50% 
    uint32[] public chanceModifier = [0, 50, 33];               // -0%, -50%,  -75%
    uint32[] public rewardModifier = [125, 150, 200];            // +25%, +50%, +100%

    //!SECTION ARRAYS --------------------------------------------------------------------------------------------------
    //  
    //
    //
    // SECTION STRUCTS _________________________________________________________________________________________________

    struct merge {

        bool   first;
        uint32 onBlock; 
        uint   mergedToken;
    }

    struct stake{
        bool staked;
        uint32 lastClaim;
    }


    //!SECTION STRUCTS -------------------------------------------------------------------------------------------------
    //  
    //
    //
    // SECTION MAPPINGS ________________________________________________________________________________________________

    mapping 
    (address => bool)   
    whitelisted;

    mapping
    (address => uint8)  
    wlBuys;

    mapping
    (uint => merge)
    mergedTo;

    mapping
    (uint => stake)
    stakedData;

    //!SECTION MAPPINGS ------------------------------------------------------------------------------------------------
    //  
    //
    //
    // SECTION REFERENCES ______________________________________________________________________________________________

    ISilver public silver;  //DETAILS ⋯ For burns

    //!SECTION REFERENCES ----------------------------------------------------------------------------------------------
    //  
    //
    //
    // SECTION CONSTRUCTOR _____________________________________________________________________________________________

    constructor (
        string  memory _name,
        string  memory _symbol,
        string  memory _initBaseURI,
        string  memory _initNotRevealedURI,
        address        _silver,
        uint           _mintCost,
        uint           _mintPerTx

    ) ERC721 (_name, _symbol) {

        mintPerTx = _mintPerTx;
        mintCost = _mintCost;
        baseURI = _initBaseURI;
        notRevealedURI = _initNotRevealedURI;
        silver = ISilver(_silver);
    }

    //!SECTION CONSTRUCTOR ---------------------------------------------------------------------------------------------
    //  
    //
    //
    // SECTION EVENTS __________________________________________________________________________________________________

    //ROLE ⋯ Event indicating a merge is being prepared
    event awaitingMerge (
        uint firstToken, 
        uint secondToken, 
        uint32 onBlock

    );  //DETAILS ⋯ "firstToken"  → Indicates which is the first token to be choosed
        //        ⋯ "secondToken" → Indicates which is the second token to be choosed
        //        ⋯ "onBlock"     → Indicates on which block was this transaction made (for randomisation purposes)

    
    //ROLE ⋯ Event indicating a merge has been claimed
    event mergeClaimed (
        uint firstToken, 
        uint secondToken, 
        uint8 number,  
        bool sucess
        
    );  //DETAILS   ⋯ "firsToken"   ...
        //          ⋯ "secondToken" ...
        //          ⋯ "number"      → Indicates which number msg.sender got for ui
        //          ⋯ "succes"      → Indicates if the merge was succesful

    //ROLE → Event indicating an useless token has been burned (must be blacklisted)
    event mergedTokensBurned (
        uint tokenId
    );

    //!SECTION EVENTS --------------------------------------------------------------------------------------------------
    //  
    //
    //
    // SECTION MODIFIERS _______________________________________________________________________________________________

    //ROLE ⋯ Make sure msg.sender has sent enough ether to cover transaction
    modifier checkValue (uint amount, bool isWl) {
        if (isWl) {
            require (msg.value >= wlMintCost * amount,
            "Not enough ether has been sent (wl)");
        } else {
            require (msg.value >= mintCost * amount,
            "Not enough ether has been sent");
        }
        require (amount <= mintPerTx, 
        "You can't mint that many at a time");
        _;
    }

    //ROLE ⋯ Make sure we do not surpass total supply
    modifier checkSupply (uint amount) {
        require (amount + totalFarmersMints <= maxSupply, 
        "Sorry, max supply for farmers has been reached");
        _;
    }

    //ROLE ⋯ Make sure msg.sender has sent enough ether to cover fees and has enough $SILVER
    modifier checkMergeValue (uint8 mergeValue, uint amount) {

        //DETAILS ⋯ Make sure "msg.sender" has sent enough ether to cover for the fees
        require (msg.value >= (perCalc(baseFees, feesModifier[mergeValue]) * amount),
        "Sorry not enough ether has been sent to cover the fees");

        //DETAILS ⋯ Make sure "msg.sender" has enough silver to cover the trasaction
        silver.burn(msg.sender, (perCalc(baseMerge, priceModifier[mergeValue]) * amount));
        _;
    }



    //!SECTION MODIFIERS -----------------------------------------------------------------------------------------------
    //  
    //
    //
    // SECTION EXTERNAL FUNCTIONS ______________________________________________________________________________________

    function mint (uint mintAmount)
    external
    whenNotPaused
    payable
    checkSupply (mintAmount)
    checkValue (
        mintAmount, 
        whitelisted[msg.sender]
    ){

        //NOTE ⋯ REQUIRES DONE WITHIN THE MODIFIERS
        
        for (uint i; i < mintAmount; i++) {
            totalFarmersMints++;
            _safeMint(msg.sender, totalFarmersMints);
        }
    }

    /*
    //ROLE ⋯ Prepares the merge of two token, and stores them in a mapping
    // ⋯ // 
    function prepareMerge (
        uint firstToken,
        uint secondToken
    ) external payable checkMergeValue (typeOf(firstToken)) {

        // ⋯ REQUIRES ⋯ // 
        //              //
        //DETAILS ⋯ Make sure msg.sender is the owner of the two tokens
        require (ownerOf(firstToken) == msg.sender && ownerOf(secondToken) == msg.sender,
        "You are not the owner of the tokens");

        //DETAILS ⋯ Make sure both tokens are the same type
        require (typeOf(firstToken) == typeOf(secondToken),
        "You can not merge two tokens of different types");

        //DETAILS ⋯ Make sure his tokens are not already blacklisted    
        require (!isBlacklisted(firstToken) && !isBlacklisted(secondToken),
        "Sorry your tokens are blacklisted");

        //DETAILS ⋯ Make sure the tokens are not exceeding maximum level
        require (typeOf(firstToken) != 3,
        "You reached the maximum level already");

        //DETAILS ⋯ Make sure the tokens are not waiting a merge already
        require (mergedTo[firstToken].mergedToken == 0 &&  mergedTo[secondToken].mergedToken == 0,
        "Sorry your token is already waiting a merge");


        // ⋯ CHANGES DONE ⋯ //
        //                  //
        mergedTo[firstToken].first        = true;
        mergedTo[firstToken].onBlock      = uint32(block.number);
        mergedTo[firstToken].mergedToken  = secondToken;

        mergedTo[secondToken].mergedToken = firstToken;

        emit awaitingMerge(firstToken, secondToken, uint32(block.number));
    }
    */

    function prepareMultipleMerges (
        uint[] memory firstTokens,
        uint[] memory secondTokens
    ) external payable checkMergeValue (typeOf(firstTokens[0]), firstTokens.length) {

        for (uint i; i < firstTokens.length; i++) {

            uint token1 = firstTokens[i];
            uint token2 = secondTokens[i];

            // ⋯ REQUIRES ⋯ // 
            //              //
            require (typeOf(token1) == typeOf(firstTokens[0]) && typeOf(token2) == typeOf(firstTokens[0]),
            "Every token needs to be the same type");

            //DETAILS ⋯ Make sure msg.sender is the owner of the two tokens
            require (ownerOf(token1) == msg.sender && ownerOf(token2) == msg.sender,
            "You are not the owner of the tokens");

            //DETAILS ⋯ Make sure both tokens are the same type
            require (typeOf(token2) == typeOf(token2),
            "You can not merge two tokens of different types");

            //DETAILS ⋯ Make sure his tokens are not already blacklisted    
            require (!isBlacklisted(token1) && !isBlacklisted(token2),
            "Sorry your tokens are blacklisted");

            //DETAILS ⋯ Make sure the tokens are not exceeding maximum level
            require (typeOf(token2) != 3,
            "You reached the maximum level already");

            //DETAILS ⋯ Make sure the tokens are not waiting a merge already
            require (mergedTo[token1].mergedToken == 0 &&  mergedTo[token2].mergedToken == 0,
            "Sorry your token is already waiting a merge");


            // ⋯ CHANGES DONE ⋯ //
            //                  //
            mergedTo[token1].first        = true;
            mergedTo[token1].onBlock      = uint32(block.number);
            mergedTo[token1].mergedToken  = token2;

            mergedTo[token2].mergedToken = token1;

            emit awaitingMerge(token1, token2, uint32(block.number));

        }
    } 


    function claimMerge (
        uint firstToken,
        uint secondToken
    ) external payable {

        // ⋯ REQUIRES ⋯ //
        //              //
        //DETAILS ⋯ Make sure msg.sender is the owner of both tokens being claimed
        require (ownerOf(firstToken) == msg.sender && ownerOf(secondToken) == msg.sender,
        "You are not the owner of both tokens");

        //DETAILS ⋯ Make sure both tokens are merged to each other first
        require (mergedTo[firstToken].mergedToken == secondToken && mergedTo[secondToken].mergedToken == firstToken,
        "Your tokens are not merged to each other or waiting a merge");

        //DETAILS ⋯ Make sure "uint firstToken" is indeed the firstToken
        require (mergedTo[firstToken].first,
        "Sorry your first token is not the first token");

        //DETAILS ⋯ Make sure at least 3 blocks have passed since the merge was created
        require (uint32(block.number) - mergedTo[firstToken].onBlock >= 3,
        "Sorry your merge is still in preparation");

        // ⋯ CHANGES DONE  ⋯ //
        //                   //
        uint8 seed = uint8(_hashCalc(mergedTo[firstToken].onBlock));
        

        //DETAILS ⋯ If merge is sucessful
        if (seed % 100 < perCalc(baseChance, chanceModifier[typeOf(firstToken)])) {

            blacklist(firstToken);
            blacklist(secondToken);

            mergeMint (typeOf(firstToken) + 1);

            emit mergeClaimed(firstToken, secondToken, seed, true);

        //DETAILS ⋯ If not
        } else {
            
            mergedTo[firstToken].first        = false;
            mergedTo[firstToken].mergedToken  = 0;
            mergedTo[secondToken].mergedToken = 0;

            emit mergeClaimed(firstToken, secondToken, seed % 100, false);
        }
        

    }


    //ROLE → Allows user to claim multiple merges
    function claimMultipleMerges (
        uint[] memory firstTokens,
        uint[] memory secondTokens

    ) external payable {

        for (uint i; i < firstTokens.length; i++) {

            uint token1 = firstTokens[i];
            uint token2 = secondTokens[i];

            // ⋯ REQUIRES ⋯ //
            //              //
            //DETAILS ⋯ Make sure msg.sender is the owner of both tokens being claimed
            require (ownerOf(token1) == msg.sender && 
                     ownerOf(token2) == msg.sender,
            "You are not the owner of both tokens");

            //DETAILS ⋯ Make sure both tokens are merged to each other first
            require (mergedTo[token1].mergedToken == token2 && 
                     mergedTo[token2].mergedToken == token1,
            "Your tokens are not merged to each other or waiting a merge");

            //DETAILS ⋯ Make sure "uint firstToken" is indeed the firstToken
            require (mergedTo[token1].first,
            "Sorry your first token is not the first token");

            //DETAILS ⋯ Make sure at least 3 blocks have passed since the merge was created
            require (uint32(block.number) - mergedTo[token1].onBlock >= 3,
            "Sorry your merge is still in preparation");

            // ⋯ CHANGES DONE  ⋯ //
            //                   //
            uint8 seed = uint8(_hashCalc(mergedTo[token1].onBlock));
                

            //DETAILS ⋯ If merge is sucessful
            if (seed % 100 < perCalc(baseChance, chanceModifier[typeOf(token1)])) {

                blacklist(token1);
                blacklist(token2);

                mergeMint (typeOf(token1) + 1);

                //NOTE → Emit that the claim has been sucessful
                emit mergeClaimed(token1, token2, seed % 100, true);

            //DETAILS ⋯ If not
            } else {

                mergedTo[token1].first        = false;
                mergedTo[token1].mergedToken  = 0;
                mergedTo[token2].mergedToken  = 0;


                //NOTE → Emit that the claim has failed
                emit mergeClaimed(token1, token2, seed % 100, false);
            }
        }
    }

    function stakeToken(uint[] memory tokenList)
    external {
        for (uint i; i > tokenList.length; i++) {

            uint token = tokenList[i];

            require (stakedData[token].staked == false,
            "Token is already staked");
            
            require (ownerOf(token) == msg.sender,
            "You are not the owner of the token");
    
            stakedData[token].staked = true;
            stakedData[token].lastClaim = uint32(block.timestamp);
            

            //TODO → Add fees for stake? 
        }
    }

    function claimTokens (uint[] memory tokenList)
    external {

        uint toPay;
        
        for (uint i; i > tokenList.length; i++) {

            uint token = tokenList[i];

            require (stakedData[token].staked == true,
            "Your token is not staked yet");
                
            require (ownerOf(token) == msg.sender,
            "You are not the owner of the token");
            
            toPay += calculateRewards(typeOf(token), stakedData[token].lastClaim);

            stakedData[token].lastClaim = uint32(block.timestamp);
        }

        silver.mint(msg.sender, toPay);

        //TODO → Add fees for claim?
    }

    function unstake (uint[] memory tokenList)
    external {

        uint toPay;
        
        for (uint i; i > tokenList.length; i++) {

            uint token = tokenList[i];

            require (stakedData[token].staked == true,
            "Your token is not even staked");

            require (ownerOf(token) == msg.sender,
            "You are not the owner of the token");

            require (stakedData[token].lastClaim > block.timestamp + 86400,
            "Your token needs to be staked for at least a day");

            toPay += calculateRewards(typeOf(token), stakedData[token].lastClaim);

            stakedData[token].staked = false;
        }

        silver.mint(msg.sender, toPay);
    }

    
    function burnMergedTokens (
        uint[] memory tokens
    ) external {

        // ⋯ REQUIRES ⋯ //
        for (uint i; i < tokens.length; i++) {
            require ( ownerOf(tokens[i]) == msg.sender, "Not your tokens");
            require ( isBlacklisted(tokens[i]), "Your token is not blacklisted" );
            _burn (tokens[i]);

        }
    }

    //!SECTION EXTERNAL FUNCTIONS --------------------------------------------------------------------------------------
    //  
    //
    //
    // SECTION INTERNAL FUNCTIONS ______________________________________________________________________________________

    function mergeMint (uint8 class) private {
        tokenIds[class]++;
        _safeMint (msg.sender, tokenIds[class]);
    }
    
    //!SECTION INTERNAL FUNCTIONS --------------------------------------------------------------------------------------
    //  
    //
    //
    // SECTION VIEW FUNCTIONS __________________________________________________________________________________________

    function calculateRewards (uint8 tokenType, uint32 lastClaim)
    internal
    pure
    returns (uint) {

        
    }

    function perCalc (uint input, uint per)
    internal
    pure
    returns (uint) {

        return input * per / 100;
    }

    function typeOf(uint tokenId) 
    public
    pure
    returns (uint8) {
        if (tokenId <= 10000) {
            return 0;
        } else if (tokenId <= 15000) {
            return 1;
        } else if (tokenId <= 17500) {
            return 2;
        } else {
            return 3;
        }
    }

    //ROLE → Returns a seed calculated from the hash of 3 blocks that were not validated yet when the order was placed.
    function _hashCalc (uint32 onBlock)
    private
    view
    returns (uint) {

        bytes32 firstBlock   = blockhash (onBlock);
        bytes32 secondBlock  = blockhash (onBlock + 1);
        bytes32 thirdBlock   = blockhash (onBlock + 2);



        return uint(
            keccak256(
                abi.encodePacked(
                    firstBlock, 
                    secondBlock, 
                    thirdBlock
                )
            )
        );
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    
    if(revealed == false) {
        return notRevealedURI;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

    //!SECTION VIEW FUNCTIONS ------------------------------------------------------------------------------------------
    //  
    //
    //
    // SECTION SETTER FUNCTIONS ________________________________________________________________________________________
  
    function changeERC20 (address _newAddress) 
    external
    onlyOwner {
        silver = ISilver(_newAddress);
    }

    function addWhitelist (address[] memory wl) 
    external 
    onlyOwner {
        for (uint i; i < wl.length; i++) {
          whitelisted[wl[i]] = true;
        }
    }

    function setMintPerWl (uint max) 
    external
    onlyOwner {
        mintPerWhitelist = max; 
    }

    function setBaseURI (string memory _newBaseURI) 
    external 
    onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNonRevealedURI(string memory newNotRevealedURI)
    external
    onlyOwner {
        notRevealedURI = newNotRevealedURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function reveal() 
    external 
    onlyOwner {
        revealed = true;
    }

    function setCost(uint newCost) 
    external 
    onlyOwner {
        mintCost = newCost;
    }
    
    function setBaseMerge (uint newCost) 
    external
    onlyOwner{
        baseMerge = newCost;
    }

    function setMergeMod (uint32[] memory newCost)
    external
    onlyOwner {
        priceModifier = newCost;
    }

    function setBaseFees (uint newCost)
    external
    onlyOwner {
        baseFees = newCost;
    }

    function setFeesMod (uint[] memory newfees)
    external 
    onlyOwner {
        feesModifier = newfees;
    }
    //!SECTION SETTER FUNCTIONS ----------------------------------------------------------------------------------------
    //  
    //
    //
}
