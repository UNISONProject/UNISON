pragma solidity 0.4.18;

import "./UNISON.sol";
import "./SafeMath.sol";



contract Crowdsale is UNISON, SafeMath {

    address public constant ethFundDeposit = 0xeE9b66740EcF1a3e583e61B66C5b8563882b5d12;                         // Deposit address for ETH
    uint256 public constant minTokenPurchaseAmount = .008 ether;  //     Minimum purchase
    uint256 public constant tokenPrice = 600;    // UNSN per 1 ETH during presale
    //uint256 public constant crowdSaleCap=100 * (10**6) * 10**decimals; //umcomment for cap
    bool public isEnabled ;
    address public admin;


   //Events for logging
    event CrowdSaleIsEnabled(bool isEnabled);
    event PayableHit(address sender,uint amount);
    event WithDrawSuccess(address recieved,uint amount);
    event PayableInit(address _sender, uint amount);
    event DonationSuccess(address, uint);


//IsAdmin or Deployer of the contract
    modifier isAdmin() {
        require(msg.sender == admin);
        _;
    }
    //Constructor
    function Crowdsale(){
         isEnabled=false;  // False at initialization
         admin=msg.sender;
      
    }
    
    // Enable and Disable sale
    function toggleSale() external isAdmin  {
        isEnabled=!isEnabled;

    }

    //get tokensale Whitelist status 

    function getIsEnabled() external returns (bool _isEnabled){
        CrowdSaleIsEnabled(isEnabled);
        return isEnabled;
    }

    //Buy tokens
    function donate() payable {
        
        PayableHit(msg.sender, msg.value);
        //check value sent
        require(msg.value > minTokenPurchaseAmount);
        
        // check active
        require(isEnabled);
        
        PayableInit(msg.sender,msg.value);
       
       // calculate quantity
        uint256 quantity = safeMult(msg.value,tokenPrice);
        mint(msg.sender, quantity);
    
    //   require(totalSupply <= crowdSaleCap); //Uncomment for cap
        DonationSuccess(msg.sender,msg.value);
        forwardFunds();

    }

   //forward funds to wallet;
    function forwardFunds() internal {
         ethFundDeposit.transfer(msg.value);
         WithDrawSuccess(ethFundDeposit,msg.value);
         
    }
    
    
    // Fallback function let user send ether without calling the donate function
    function () payable{
        donate();

    }



}
