//SPDX-License-Identifier: MIT


// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
    unchecked {
        counter._value += 1;
    }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
    unchecked {
        counter._value = value - 1;
    }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts/GoalGuardian.sol

pragma solidity ^0.8.10;

//Interface for other collections. We use it to check wether the user receives an NFT-Certificate which marks completion of this challenge
interface ProofInterface {
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
    function balanceOf(address _owner) external view returns (uint256 balance);
}
contract GoalGuardian_flattened is Ownable   {
    using Counters for Counters.Counter;

    uint pendingBetAmounts = 0; //Stores money reserved for users

    //Tracks current ids of all challenges for iteration and incrementing
    Counters.Counter private _challengeIds;
    Counters.Counter private _counterChallengeIds;


    event newChallenge(uint indexed id, string indexed description,  uint indexed value);
    event newCounterChallenge(uint indexed id, string indexed description,  uint indexed value);
    event claim(uint indexed id, string indexed description,  uint indexed value);
    event counterClaim(uint indexed id, string indexed description,  uint indexed value);


    //Stores all challenges and counterChallenges
    mapping (uint => Challenge ) challenges;
    mapping (uint => CounterChallenge ) counterChallenges;

    struct Challenge {
        uint id;
        address benefactor;
        string name;
        string description;
        address proofCollection;
        uint creationTimestamp;
        uint timeframeInDays;
        uint value;
        bool active;
    }

    struct CounterChallenge{
        uint id;
        Challenge challenge;
        address benefactor;
        uint value;
        bool active;
    }

    //Anyone can create a bet. If the condition is fullfilled, which is fullfilled if they own a certain NFT
    function createChallenge(address _benefactor,  string memory _name, string memory _description, address _proofCollection, uint _timeframeInDays, uint value) public payable {
        require(msg.value >= value, "Ether value sent is below the challengeamount");
        require(checkIfCompleted(msg.sender,_proofCollection),"Bet is already fullfilled and therefore unfair"); //Wenn bet created, hat er das NFT schon? Falls ja, abort, das ist scam

        //Calculate challenge id
        _challengeIds.increment();
        pendingBetAmounts += msg.value;

        challenges[_challengeIds.current()] = Challenge(_challengeIds.current()  ,_benefactor,   _name,  _description,  _proofCollection, block.timestamp,  _timeframeInDays,  value, true);
        emit newChallenge(_challengeIds.current() , _description, value );
}

    //Anyone can create a bet. If the condition is fullfilled, which is fullfilled if they own a certain NFT
    function createCounterChallenge( uint challengeId, address _benefactor, uint value) public payable {
        require(msg.value >= value, "Ether value sent is below the challengeamount");
        Challenge memory enemyChallenge = challenges[challengeId];

        //Calculate CounterChallenge id
        _counterChallengeIds.increment();
        pendingBetAmounts += msg.value;

        counterChallenges[_counterChallengeIds.current()] = CounterChallenge(_counterChallengeIds.current(), enemyChallenge  ,_benefactor, value, true);
        //Wenn bet created, hat er das NFT schon? Falls ja, abort, das ist scam
        emit newCounterChallenge(_counterChallengeIds.current() , enemyChallenge.description, value);
    }

    //Checks wether the bet is completed through checking wether the confirmation NFT was received
    function checkIfCompleted (address _owner, address _proofCollection) internal view returns(bool){
        ProofInterface ProofContract = ProofInterface(_proofCollection);
        return ProofContract.balanceOf(_owner) >=1;
    }

    //Checks wether the claim + goal was performed in the given timeframe
    function checkIfCompletedInTime (Challenge memory _myChallenge, uint _finished) internal pure returns(bool){
        return _myChallenge.creationTimestamp +  _myChallenge.timeframeInDays >= _finished;
    }

    //Claims the money for the winning bet
    function challengeClaim(uint _MyChallengeId) public { //Bestimmes nft, von bestimmtem Contract, timestamp von nftmint
        // check if user made it in time
        Challenge memory MyChallenge = challenges[_MyChallengeId];
        require(msg.sender == MyChallenge.benefactor, "You are not the benefactor of this challenge");
        require(MyChallenge.active, "Bet is inactive");
        require(checkIfCompleted(MyChallenge.benefactor, MyChallenge.proofCollection), "Challenge was not completed");

        //Future: Replace block.timestamp by creation time of nft, to allow for more time to claim
        require(checkIfCompletedInTime(MyChallenge, block.timestamp), "Finished to late");
        MyChallenge.active = false;
        pendingBetAmounts -= MyChallenge.value;

        uint amountIncludingCounterChallenge = sumUp(_MyChallengeId) + MyChallenge.value;

        // Deny claims of Counterparty
        closeCounterChallenges(_MyChallengeId);
        emit newChallenge(_MyChallengeId , MyChallenge.description, amountIncludingCounterChallenge );
        payable(msg.sender).transfer(amountIncludingCounterChallenge);
    }

    //Claims the money for the counterChallengeBet
    function counterChallengeClaim(uint _CounterChallengeId) public { //Bestimmes nft, von bestimmtem Contract, timestamp von nftmint
        // check if user made it in time
        CounterChallenge memory MyCounterChallenge = counterChallenges[_CounterChallengeId];
        require(msg.sender == MyCounterChallenge.benefactor, "You are not the benefactor of this challenge");
        require(MyCounterChallenge.active, "Bet is inactive");
        require(!checkIfCompleted(MyCounterChallenge.challenge.benefactor, MyCounterChallenge.challenge.proofCollection), "Challenge was completed, therefore your Counterclaim is ineligible");

        require(!checkIfCompletedInTime(MyCounterChallenge.challenge, block.timestamp), "They finished and claimed in time");


        uint percentageShares = (MyCounterChallenge.value * 100) / sumUp(MyCounterChallenge.challenge.id);
        //His/Her Money
        uint cashOut = MyCounterChallenge.value + (sumUp(MyCounterChallenge.challenge.id) * 100 / percentageShares);
        pendingBetAmounts -= cashOut;

        MyCounterChallenge.active = false;
        emit newChallenge(_CounterChallengeId , MyCounterChallenge.challenge.description, cashOut );
        payable(msg.sender).transfer(cashOut);
    }


    //Button calls this function to claim either challenge or counterChallenge for convinience
    function result(bool challengeOrCounterChallenge, uint _challengeId) public {
        if(challengeOrCounterChallenge){
            challengeClaim(_challengeId);
        }else {
            counterChallengeClaim(_challengeId);
        }
    }

    //---------------------------------------helpers-------------------------------------------------//
    //Sum up all amounfs of counterchallenges
    function sumUp (uint _challengeId) public view returns (uint){
        uint counterBettedEth =0;
        for(uint i = 0; i < _counterChallengeIds.current() ;i++){
            if(counterChallenges[i].challenge.id == _challengeId){
                counterBettedEth += counterChallenges[i].challenge.value;
            }
        }
        return counterBettedEth;
    }

    //Close all bets against my challenge
    function closeCounterChallenges(uint _myChallengeid) internal {
        for(uint i = 0; i < _counterChallengeIds.current() ;i++){
            if(counterChallenges[i].challenge.id == _myChallengeid){
                counterChallenges[i].active = false;
            }
        }
    }

    //Getter to find out who gets the money in case of win
    function getBenefactorChallenge(uint _challengeId) public view returns (address){
        return challenges[_challengeId].benefactor;
    }

    //Getter to find out who gets the money in case of win
    function getBenefactorCounterChallenge(uint _challengeId) public view returns (address){
        return counterChallenges[_challengeId].benefactor;
    }

    //Projectowners beeing able to  recieve the contracts's leftover funds
    //Make sure they can't grab active bets, only money that has been forfeitet
    function withdrawAll() public onlyOwner {
        uint claimableForOwners = address(this).balance - pendingBetAmounts;

        bool sent =  payable(msg.sender).send(claimableForOwners);
        require(sent, "Sending failed");
    }

}
