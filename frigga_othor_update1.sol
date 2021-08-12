pragma solidity ^0.6.3;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initOwnable() internal{
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

contract FriggaThor is Ownable, Initializable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        mapping(uint8 => bool) activeMatrixLevels;
        mapping(uint8 => Matrix) matrixes;
    }
    
    struct Matrix {
        address upperAddress;
        address[] lowerAddresses;
        uint8 recycleCount;
        bool missed;
        uint reinvestCount;
        uint partnersCount;
    }
    
    address public constant othorAddress = address(0x3F701Ac65A592468824AAE00C9AC6d167d68C0d4);
    uint8 public constant LAST_LEVEL = 8;
    uint256 public constant decimals = 18;
    uint256 public constant entryAmount = 2000000000000000000;
    uint256 public constant powerThreshold = 10000000; 

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(address => uint256) public putCoins;
    mapping(address => uint256) public getCoins;
    mapping(address => uint256) public receivedCoins; 
    mapping(address => uint256) public receivedPowers; 
    
    mapping(address => uint256) public shareGetCoins; 
    mapping(address => uint256) public miningGetCoins; 
    mapping(address => uint256) public rewardGetCoins; 

    uint public lastUserId ;
    address public root;
        
    mapping(uint8 => uint256) public levelPrice;
    
    uint256 public shareIncome; 
    uint256 public miningIncome; 
    uint256 public rewardIncome; 
    address public technologyAddress;
    
    uint256 public shareAirdroped;
    uint256 public miningAirdroped;
    
    uint256[8] public userShareAirdrop;
    uint256 public todayMiningIncome;
    
    uint256 public totalPower;
    
    uint256[6] public rewardSco;
    uint256[6] public rewardScale;
    address[6] public rewardUser;
    uint256[8] public unprofitUserCount;
    uint256[8] public shareLevelScale;
    mapping(address => uint256) public userRewardLevel; 
    
    mapping(uint256 => mapping(address => bool)) public dailyDroppedUser;
    
    uint256 public lastDay;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed upperAddress, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed upperAddress, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed upperAddress, uint8 matrix, uint8 level, uint8 place);
    event MissedReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraCoinDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event SendCoin(address indexed from, address indexed to, uint256 amount);
    event Airdrop(address user, uint256 amount1, uint256 amount2, uint256 day);
    event DistributeCoin(address from, uint8 level);
    event Reward(address receiver, uint256 rewardLevel, uint256 rewardAmount);
    
    constructor() public {
    }
    
    function registrationExt(address referrerAddress) external {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 level) external {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        require(!users[msg.sender].activeMatrixLevels[level], "level already activated");
        
        IERC20(othorAddress).safeTransferFrom(msg.sender, address(this), levelPrice[level] * 2);
        
        if (users[msg.sender].matrixes[level-1].recycleCount > 0) {
            users[msg.sender].matrixes[level-1].recycleCount = 0;
            users[msg.sender].matrixes[level-1].missed = false;
        }

        address newUpperAddress = findActiveMatrixUpperAddress(msg.sender, level);
        users[msg.sender].matrixes[level].upperAddress = newUpperAddress;
        users[newUpperAddress].matrixes[level].partnersCount ++;
        users[msg.sender].activeMatrixLevels[level] = true;
        
        uint256 oldPut = putCoins[msg.sender];
        putCoins[msg.sender] = putCoins[msg.sender].add(levelPrice[level] * 2);
        addPower(msg.sender, levelPrice[level] * 2);
        if(putCoins[msg.sender] > getCoins[msg.sender] && oldPut <= getCoins[msg.sender]){
            unprofitUserAddAllLevel(msg.sender); 
        }
        else if (putCoins[msg.sender] > getCoins[msg.sender]){
            unprofitUserAddOneLevel(msg.sender, level);
        }
        
        distributeCoin(msg.sender, level);
        updateMatrix(msg.sender, newUpperAddress, level);
        
        emit Upgrade(msg.sender, newUpperAddress, 1, level);
        
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        IERC20(othorAddress).safeTransferFrom(msg.sender, address(this), entryAmount);
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeMatrixLevels[1] = true; 
        
        lastUserId++;
        
        users[referrerAddress].partnersCount++;
        users[referrerAddress].matrixes[1].partnersCount ++;
        
        putCoins[msg.sender] = putCoins[msg.sender].add(entryAmount);
        addPower(msg.sender, entryAmount);
        unprofitUserAddOneLevel(msg.sender, 1);
        
        address upperAddress = findActiveMatrixUpperAddress(userAddress, 1);
        users[userAddress].matrixes[1].upperAddress = upperAddress;
        
        distributeCoin(userAddress, 1);
        updateMatrix(userAddress, upperAddress, 1);

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateMatrix(address userAddress, address upperAddress, uint8 level) private {
     
        users[upperAddress].matrixes[level].lowerAddresses.push(userAddress);

        if (users[upperAddress].matrixes[level].lowerAddresses.length < 3) {
            emit NewUserPlace(userAddress, upperAddress, 1, level, uint8(users[upperAddress].matrixes[level].lowerAddresses.length));
            return sendCoin(upperAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, upperAddress, 1, level, 3);
        //close matrix
        users[upperAddress].matrixes[level].lowerAddresses = new address[](0);
        if (!users[upperAddress].activeMatrixLevels[level+1] && level != LAST_LEVEL) {
            users[upperAddress].matrixes[level].recycleCount++;
        }

        //create new one by recursion
        if (upperAddress != root) {
            //check referrer active level
            address nextUpperAddress = findActiveMatrixUpperAddress(upperAddress, level);
            if (users[upperAddress].matrixes[level].upperAddress != nextUpperAddress) {
                users[upperAddress].matrixes[level].upperAddress = nextUpperAddress;
            }
            
            users[upperAddress].matrixes[level].reinvestCount++;
            emit Reinvest(upperAddress, nextUpperAddress, userAddress, 1, level);
            updateMatrix(upperAddress, nextUpperAddress, level);
        } else {
            sendCoin(root, userAddress, 1, level);
            users[root].matrixes[level].reinvestCount++;
            emit Reinvest(root, address(0), userAddress, 1, level);
        }
    }
    
    function findUnblockedUpperAddress(address userAddress, uint8 level) private view returns(address) {
        if (userAddress == root) return address(0);
        address upperAddress = users[userAddress].matrixes[level].upperAddress;
        
        while (true) {
            if (users[upperAddress].matrixes[level].recycleCount >= 2) {
                upperAddress = users[upperAddress].matrixes[level].upperAddress;
            } else { 
                return upperAddress;
            }
        }
    }
    
    function addPower(address userAddress, uint256 coins) private{
        uint256 power = coins.div(10 ** decimals).mul(100);
        totalPower = totalPower.add(power);
        uint256 oldPower = receivedPowers[userAddress];
        receivedPowers[userAddress] = oldPower.add(power);

    }
    
    
    function findActiveMatrixUpperAddress(address userAddress, uint8 level) private view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeMatrixLevels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    

    function userActiveMatrixLevel(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeMatrixLevels[level];
    }

    function userMatrixReinvestCount(address userAddress) public view returns(uint256[] memory) {
        uint256[] memory counts = new uint256[](8);
        
        for (uint8 i = 1; i <= 8; i ++){
            counts[i - 1] = users[userAddress].matrixes[i].reinvestCount;
        }
        
        return counts;
    }
    
    function userMatrixPartnersCount(address userAddress) public view returns(uint256[] memory) {
        uint256[] memory counts = new uint256[](8);
        
        for (uint8 i = 1; i <= 8; i ++){
            counts[i - 1] = users[userAddress].matrixes[i].partnersCount;
        }
        
        return counts;
    }
    
    function userActiveMatrixLevels(address userAddress) public view returns(bool[] memory) {
        bool[] memory actives = new bool[](8);
        
        for (uint8 i = 1; i <= 8; i ++){
            actives[i - 1] = users[userAddress].activeMatrixLevels[i];
        }
        
        return actives;
    }
    
    
    function userMissedMatrixLevels(address userAddress) public view returns(bool[] memory) {
        bool[] memory misses = new bool[](8);
        
        for (uint8 i = 1; i <= 8; i ++){
            misses[i - 1] = users[userAddress].matrixes[i].missed;
        }
        
        return misses;
    }
    
    
    function userMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].matrixes[level].upperAddress,
                users[userAddress].matrixes[level].lowerAddresses,
                users[userAddress].matrixes[level].recycleCount>=2);
    }

    function userLowerAddresses(address userAddress) public view returns(address[3][8] memory lowerAddresses) {
        for (uint8 level = 1; level <= 8; level ++){
            address[] memory lowers = users[userAddress].matrixes[level].lowerAddresses;
            if (lowers.length > 0){
                for (uint8 j = 0; j < lowers.length; j ++){
                    lowerAddresses[level - 1][j] = lowers[j];
                }
            }
        }
    }
    
    function userMatrixInfo(address userAddress) public view returns(uint256[] memory, uint256[] memory, bool[] memory, bool[]memory, address[3][8] memory){
        uint256[] memory a = userMatrixReinvestCount(userAddress);
        uint256[] memory b = userMatrixPartnersCount(userAddress);
        bool[] memory c = userActiveMatrixLevels(userAddress);
        bool[] memory d = userMissedMatrixLevels(userAddress);
        address[3][8] memory e = userLowerAddresses(userAddress);
        return(a, b, c, d, e);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }


    function findCoinReceiver(address userAddress, address from, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        
        while (true) {
            if (users[receiver].matrixes[level].recycleCount >= 2) {
                emit MissedReceive(receiver, from, 1, level);
                users[receiver].matrixes[level].missed = true;
                isExtraDividends = true;
                receiver = users[receiver].matrixes[level].upperAddress;
            } else {
                return (receiver, isExtraDividends);
            }
        }
        
    }

    function sendCoin(address userAddress, address from, uint8 matrix, uint8 level) private {
        //send coin 
        (address receiver, bool isExtraDividends) = findCoinReceiver(userAddress, from, level);
        emit SendCoin(from, receiver, levelPrice[level]);
        
        uint256 oldGet = getCoins[receiver];
        
        receivedCoins[receiver] = receivedCoins[receiver].add(levelPrice[level]);
        getCoins[receiver] = getCoins[receiver].add(levelPrice[level]);
        
        if(getCoins[receiver]>=putCoins[receiver] && oldGet<putCoins[receiver]){
            unprofitUserRemoveAllLevel(msg.sender); 
        }
        
        IERC20(othorAddress).safeTransfer(receiver, levelPrice[level]);
        
        if (receiver != root){
            countReward(receiver);
        }

        if (isExtraDividends) {
            emit SentExtraCoinDividends(from, receiver, matrix, level);
        }
    }
    
    function distributeCoin(address from, uint8 level) private {
        uint256 price = levelPrice[level];
        
        shareIncome = shareIncome.add(price.mul(60).div(100));
        miningIncome = miningIncome.add(price.mul(20).div(100));
        rewardIncome = rewardIncome.add(price.mul(10).div(100));
        IERC20(othorAddress).safeTransfer(technologyAddress, price.mul(10).div(100));
        
        emit DistributeCoin(from, level);
    }

    function countReward(address receiver) private {
        uint256 rewardLevel = userRewardLevel[receiver];
        if((rewardLevel<rewardSco.length) && (receivedCoins[receiver] >= rewardSco[rewardLevel])){
            uint256 rewardAmount = rewardIncome.mul(rewardScale[rewardLevel]).div(100);
            rewardIncome = rewardIncome.sub(rewardAmount);
            rewardUser[rewardLevel] = receiver;
            emit Reward(receiver, rewardLevel, rewardAmount);
            rewardLevel++;
            userRewardLevel[receiver]=rewardLevel;
            IERC20(othorAddress).safeTransfer(receiver, rewardAmount);
            getCoins[receiver] = getCoins[receiver].add(rewardAmount);
            rewardGetCoins[receiver] = rewardGetCoins[receiver].add(rewardAmount); 
            
        }    
    }
    

    function airdrop(address[] memory addrs)  public {
        uint256 day = today();
        if (day > lastDay){
            shareIncome = shareIncome.sub(shareAirdroped);
            miningIncome = miningIncome.sub(miningAirdroped);
            shareAirdroped = 0;
            miningAirdroped = 0;
            
            for (uint8 i = 0; i < shareLevelScale.length; i++) {
                if(unprofitUserCount[i]>0){
                    userShareAirdrop[i] = shareIncome.mul(shareLevelScale[i]).div(100).div(unprofitUserCount[i]);           
                }
                else{
                    userShareAirdrop[i] = 0;
                }
            }
            todayMiningIncome = miningIncome.mul(15).div(1000);
            lastDay = day;
        }
        
        for (uint i= 0; i < addrs.length; i++){
            _airdropSingle(addrs[i], day);
        }
         
    }

    function _airdropSingle(address user, uint256 day) private {
        if (dailyDroppedUser[day][user] == true){ // "User has been airdropped."
            return;
        }
        if(putCoins[user] == 0){
             return;
        }
        uint256 amount1 = 0;
        uint256 amount2 = 0;
        if(putCoins[user] > getCoins[user]){
            uint256 unprofitAmount = putCoins[user].sub(getCoins[user]);
            for (uint8 i = 0; i < shareLevelScale.length; i++) {
                if(users[user].activeMatrixLevels[i+1] && unprofitUserCount[i] > 0 && userShareAirdrop[i] > 0 && amount1 < unprofitAmount){
					uint256 airdropAmount = userShareAirdrop[i];
					if(amount1.add(airdropAmount) >= unprofitAmount){
						airdropAmount = unprofitAmount.sub(amount1);
						amount1 = unprofitAmount;
						shareGetCoins[user] = shareGetCoins[user].add(airdropAmount);
						shareAirdroped = shareAirdroped.add(airdropAmount);
						break;
					}else{
						amount1 = amount1.add(airdropAmount);
						shareGetCoins[user] = shareGetCoins[user].add(airdropAmount);
						shareAirdroped = shareAirdroped.add(airdropAmount);
					}
                    
                }
            }
        } 
        
        if(totalPower >= powerThreshold){
            uint256 userPower = receivedPowers[user];
            uint256 userMiningIncome = todayMiningIncome.mul(userPower).div(totalPower);
            if (userMiningIncome > 0){//air drop coins
                amount2 = userMiningIncome;   
                miningGetCoins[user] = miningGetCoins[user].add(userMiningIncome); 
                miningAirdroped = miningAirdroped.add(userMiningIncome);
            }
        }
        uint256 amount = amount1.add(amount2);
        IERC20(othorAddress).safeTransfer(user, amount);
        uint256 oldGet = getCoins[user];
        getCoins[user] = oldGet.add(amount);
        if(getCoins[user]>=putCoins[user] && oldGet<putCoins[user]){
            unprofitUserRemoveAllLevel(msg.sender); 
        }
        
        dailyDroppedUser[day][user] = true;
        emit Airdrop(user, amount1, amount2, day);
    }
    
    function unprofitUserAddAllLevel(address user) private{
        for (uint8 i = 0; i < shareLevelScale.length; i++) {
            if(users[user].activeMatrixLevels[i+1]){
                unprofitUserCount[i] = unprofitUserCount[i].add(1);
            }
        }
    }
    
    function unprofitUserAddOneLevel(address user, uint8 level) private{
        require(level > 0);
        if(users[user].activeMatrixLevels[level]){
            unprofitUserCount[level-1] = unprofitUserCount[level-1].add(1);
        }
    }
    
    function unprofitUserRemoveAllLevel(address user) private{
        for (uint8 i = 0; i < shareLevelScale.length; i++) {
            if(users[user].activeMatrixLevels[i+1]){
                if (unprofitUserCount[i] > 0){
                    unprofitUserCount[i] = unprofitUserCount[i].sub(1);
                }
            }
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
     function getDay(uint256 unix) public pure returns (uint256) {
        return unix / 1 days;
    }
    
    function today() public view returns (uint256) {
        return block.timestamp / 1 days;
    }
    
    function time() public view returns (uint256) {
        return block.timestamp;
    }
    
    function userData(address user) public view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256) { 
        return (putCoins[user],receivedCoins[user],getCoins[user],receivedPowers[user],shareGetCoins[user],miningGetCoins[user],rewardGetCoins[user]);
    }
    
    function tolalData() public view returns (uint256,uint256,uint256,address[6] memory,uint256) { 
        return (shareIncome,miningIncome,rewardIncome,rewardUser,totalPower);
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
