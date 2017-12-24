pragma solidity 0.4.18;

import "./ERC20.sol";
import "./Safemath.sol";
import "./Ownable.sol";

contract UNSToken is ERC20,Ownable, SafeMath {

    // crowdsale parameters
    string  public constant name = "UNSCoin";
    string  public constant symbol = "UNS";
    uint256 public constant decimals = 18;
    string  public version = "1.0";
    address public constant ethFundDeposit= 0x1b0fc1cee738a46d3fcb23d63245df14890cb001;   // Deposit address for ETH, will be changed at the time of deployment 
    bool public emergencyFlag;                                      //  Switched to true in  crownsale end  state
    uint256 public fundingStartBlock;                              //   Starting blocknumber
    uint256 public fundingEndBlock;                               //    Ending blocknumber
    uint256 public constant minTokenPurchaseAmount= .008 ether;  //     Minimum purchase
    uint256 public constant tokenPreSaleRate=875;    // UNS per 1 ETH during presale
    uint256 public constant tokenCrowdsaleRate=700; //  UNS per 1 ETH during crowdsale
    uint256 public constant tokenCreationPreSaleCap =  10 * (10**6) * 10**decimals;// 10 million token cap for presale
    uint256 public constant tokenCreationCap =  50 * (10**6) * 10**decimals;      //  50 million token generated
    uint256 public constant preSaleBlockNumber = 10000;
    uint256 public finalBlockNumber = 202202;


    // events
    event CreateUNS(address indexed _to, uint256 _value);// Return address of buyer and purchase token
    event Mint(address indexed _to,uint256 _value);     //  Reutrn address to which we send the mint token and token assigned.
    // Constructor
    function UNSToken(){
      emergencyFlag = false;                             // False at initialization will be false during ICO
      fundingStartBlock = block.number;                 //  Current deploying block number is the starting block number for ICO
      fundingEndBlock=safeAdd(fundingStartBlock,finalBlockNumber);  //   Ending time depending upon the block number
    }

    /**
    * @dev creates new UNS tokens
    *      It is a internal function it will be called by fallback function or buyToken functions.
    */
    function createTokens() internal  {
      if (emergencyFlag) revert();                     //  Revert when the sale is over before time and emergencyFlag is true.
      if (block.number > fundingEndBlock) revert();   //   If the blocknumber exceed the ending block it will revert
      if (msg.value<minTokenPurchaseAmount)revert();  //    If someone send 0.08 ether it will fail
      uint256 tokenExchangeRate=tokenRate();        //     It will get value depending upon block number and presale cap
      uint256 tokens = safeMult(msg.value, tokenExchangeRate);//  Calculating number of token for sender
      totalSupply = safeAdd(totalSupply, tokens);            //   Add token to total supply
      if(totalSupply>tokenCreationCap)revert();             //    Check the total supply if it is more then hardcap it will throw
      balances[msg.sender] += tokens;                      //     Adding token to sender account
      CreateUNS(msg.sender, tokens);                      //      Logs sender address and  token creation
    }

    /**
    * @dev people can access contract and choose buyToken function to get token
    *It is used by using myetherwallet
    *It is a payable function it will be called by sender.
    */
    function buyToken() payable external{
      createTokens();   // This will call the internal createToken function to get token
    }

    /**
    * @dev      it is a internal function called by create function to get the amount according to the blocknumber.
    * @return   It will return the token price at a particular time.
    */
    function tokenRate() internal returns (uint256 _tokenPrice){
      // It is a presale it will return price for presale
      if(block.number<safeAdd(fundingStartBlock,preSaleBlockNumber)&&(totalSupply<tokenCreationPreSaleCap)){
          return tokenPreSaleRate;
        }else{
            return tokenCrowdsaleRate;
        }
    }

    /**
    * @dev     it will  assign token to a particular address by owner only
    * @param   _to the address whom you want to send token to
    * @param   _amount the amount you want to send
    * @return  It will return true if success.
    */
    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
      if (emergencyFlag) revert();
      totalSupply = safeAdd(totalSupply,_amount);// Add the minted token to total suppy
      if(totalSupply>tokenCreationCap)revert();
      balances[_to] +=_amount;                 //   Adding token to the input address
      Mint(_to, _amount);                     //    Log the mint with address and token given to particular address
      return true;
    }

    /**
    * @dev     it will change the ending date of ico and access by owner only
    * @param   _newBlock enter the future blocknumber
    * @return  It will return the blocknumber
    */
    function changeEndBlock(uint256 _newBlock) external onlyOwner returns (uint256 _endblock )
    {   // we are expecting that owner will input number greater than current block.
        require(_newBlock > fundingStartBlock);
        fundingEndBlock = _newBlock;         // New block is assigned to extend the Crowd Sale time
        return fundingEndBlock;
    }

    /**
    * @dev   it will let Owner withdrawn ether at any time during the ICO
    **/
    function drain() external onlyOwner {
        if (!ethFundDeposit.send(this.balance)) revert();// It will revert if transfer fails.
    }

    /**
    * @dev  it will let Owner Stop the crowdsale and mint function to work.
    *
    */
    function emergencyToggle() external onlyOwner{
      emergencyFlag = !emergencyFlag;
    }

    // Fallback function let user send ether without calling the buy function.
    function() payable {
      createTokens();

    }


}