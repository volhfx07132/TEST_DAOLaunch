// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "../unitls/ReentrancyGuard.sol";
import "../common/TransferHelper.sol";
import "../common/IUniswapV2Factory.sol";
import "../common/IPresaleLockForwarder.sol";
import "../common/IWETH.sol";
import "../common/IPresaleSettings.sol";
import "../common/IERC20Custom.sol";

contract Presale01 is ReentrancyGuard {
    struct PresaleInfo {
        address payable PRESALE_OWNER;
        IERC20Custom S_TOKEN; // sale token
        IERC20Custom B_TOKEN; // base token // usually WETH (ETH)
        uint256 TOKEN_PRICE; // 1 base token = ? s_tokens, fixed price
        uint256 MAX_SPEND_PER_BUYER; // maximum base token BUY amount per account
        uint256 MIN_SPEND_PER_BUYER; // maximum base token BUY amount per account
        uint256 AMOUNT; // the amount of presale tokens up for presale
        uint256 HARDCAP;
        uint256 SOFTCAP;
        uint256 LIQUIDITY_PERCENT; // divided by 1000
        uint256 LISTING_RATE; // fixed rate at which the token will list on uniswap
        uint256 START_TIME;
        uint256 END_TIME;
        uint256 LOCK_PERIOD; // unix timestamp -> e.g. 2 weeks
        uint256 UNISWAP_LISTING_TIME;
        bool PRESALE_IN_ETH; // if this flag is true the presale is raising ETH, otherwise an ERC20 token such as DAI
        uint8 ADD_LP;
    }

    struct PresaleFeeInfo {
        uint256 DAOLAUNCH_BASE_FEE; // divided by 1000
        uint256 DAOLAUNCH_TOKEN_FEE; // divided by 1000
        address payable BASE_FEE_ADDRESS;
        address payable TOKEN_FEE_ADDRESS;
    }

    struct PresaleStatus {
        bool WHITELIST_ONLY; // if set to true only whitelisted members may participate
        bool LIST_ON_UNISWAP;
        bool IS_TRANSFERED_FEE;
        bool IS_OWNER_WITHDRAWN;
        uint256 TOTAL_BASE_COLLECTED; // total base currency raised (usually ETH)
        uint256 TOTAL_TOKENS_SOLD; // total presale tokens sold
        uint256 TOTAL_TOKENS_WITHDRAWN; // total tokens withdrawn post successful presale
        uint256 TOTAL_BASE_WITHDRAWN; // total base tokens withdrawn on presale failure
        uint256 NUM_BUYERS; // number of unique participants
    }

    struct BuyerInfo {
        uint256 baseDeposited; // total base token (usually ETH) deposited by user, can be withdrawn on presale failure
        uint256 tokensOwed; // num presale tokens a user is owed, can be withdrawn on presale success
        uint256 lastWithdraw; // day of the last withdrawing. If first time => = firstDistributionType
        uint256 totalTokenWithdraw; // number of tokens withdraw
        bool isWithdrawnBase;
        // bool isRefunded; // refund or claim
    }

    struct GasLimit {
        uint256 transferPresaleOwner;
        uint256 listOnUniswap;
    }

    struct VestingPeriod {
        // if set time for user withdraw at listing : use same data in uint_params[11], otherwise set new Date for it
        uint256 firstDistributionType;
        uint256 firstUnlockRate;
        uint256 distributionInterval;
        uint256 unlockRateEachTime;
        uint256 maxPeriod;
    }

    PresaleInfo private PRESALE_INFO;
    PresaleFeeInfo public PRESALE_FEE_INFO;
    PresaleStatus public STATUS;
    address public PRESALE_GENERATOR;
    IPresaleLockForwarder public PRESALE_LOCK_FORWARDER;
    IPresaleSettings public PRESALE_SETTINGS;
    IUniswapV2Factory public UNI_FACTORY;
    IWETH public WETH;
    mapping(address => BuyerInfo) public BUYERS;
    address payable public CALLER;
    GasLimit public GAS_LIMIT;
    address payable public DAOLAUNCH_DEV;
    VestingPeriod public VESTING_PERIOD;
    mapping(address => bool) public admins;

    uint256 public TOTAL_FEE;
    uint8 public PERCENT_FEE;

    mapping(address => uint256) public USER_FEES;
    uint256 public TOTAL_TOKENS_REFUNDED; // total tokens refund
    uint256 public TOTAL_FEES_REFUNDED; // total fees refund

    constructor(address _presaleGenerator, address[] memory _admins) payable {
        PRESALE_GENERATOR = _presaleGenerator;
        UNI_FACTORY = IUniswapV2Factory(
            0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73
        );
        WETH = IWETH(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        PRESALE_SETTINGS = IPresaleSettings(
            0xcFb2Cb97028c4e2fe6b868D685C00ab96e6Ec370
        );
        PRESALE_LOCK_FORWARDER = IPresaleLockForwarder(
            0x57f443f5A891fC53C43b6D9Fb850fC068af76bF4
        );
        GAS_LIMIT = GasLimit(200000, 4000000);
        DAOLAUNCH_DEV = payable(0x75d69272c5A9d6FCeC0D68c547776C7195f73feA);
        for (uint256 i = 0; i < _admins.length; i++) {
            admins[_admins[i]] = true;
        }
    }

    function init1(address payable _presaleOwner, uint256[11] memory data)
        external
    {
        require(msg.sender == PRESALE_GENERATOR, "FORBIDDEN");
        PRESALE_INFO.PRESALE_OWNER = _presaleOwner;
        PRESALE_INFO.AMOUNT = data[0];
        PRESALE_INFO.TOKEN_PRICE = data[1];

        PRESALE_INFO.MAX_SPEND_PER_BUYER = data[2];
        PRESALE_INFO.MIN_SPEND_PER_BUYER = data[3];

        PRESALE_INFO.HARDCAP = data[4];
        PRESALE_INFO.SOFTCAP = data[5];

        PRESALE_INFO.LIQUIDITY_PERCENT = data[6];
        PRESALE_INFO.LISTING_RATE = data[7];

        PRESALE_INFO.START_TIME = data[8];
        PRESALE_INFO.END_TIME = data[9];
        PRESALE_INFO.LOCK_PERIOD = data[10];
    }

    function init2(
        IERC20Custom _baseToken,
        IERC20Custom _presaleToken,
        uint256[3] memory data,
        address payable _baseFeeAddress,
        address payable _tokenFeeAddress
    ) external {
        require(msg.sender == PRESALE_GENERATOR, "FORBIDDEN");
        PRESALE_INFO.PRESALE_IN_ETH = address(_baseToken) == address(WETH);
        PRESALE_INFO.S_TOKEN = _presaleToken;
        PRESALE_INFO.B_TOKEN = _baseToken;
        PRESALE_FEE_INFO.DAOLAUNCH_BASE_FEE = data[0];
        PRESALE_FEE_INFO.DAOLAUNCH_TOKEN_FEE = data[1];
        PRESALE_INFO.UNISWAP_LISTING_TIME = data[2];

        PRESALE_FEE_INFO.BASE_FEE_ADDRESS = _baseFeeAddress;
        PRESALE_FEE_INFO.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
    }

    function init3(
        bool is_white_list,
        address payable _caller,
        uint256[5] memory data,
        uint8 _addLP,
        uint8 _percentFee
    ) external {
        require(msg.sender == PRESALE_GENERATOR, "FORBIDDEN");

        STATUS.WHITELIST_ONLY = is_white_list;
        CALLER = _caller;
        VESTING_PERIOD.firstDistributionType = data[0];
        VESTING_PERIOD.firstUnlockRate = data[1];
        VESTING_PERIOD.distributionInterval = data[2];
        VESTING_PERIOD.unlockRateEachTime = data[3];
        VESTING_PERIOD.maxPeriod = data[4];
        PRESALE_INFO.ADD_LP = _addLP;
        PERCENT_FEE = _percentFee;
    }

    modifier onlyPresaleOwner() {
        require(PRESALE_INFO.PRESALE_OWNER == msg.sender, "NOT PRESALE OWNER");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "NOT ADMIN");
        _;
    }

    modifier onlyPresaleOwnerOrAdmin() {
        require(PRESALE_INFO.PRESALE_OWNER == msg.sender || admins[msg.sender], "NOT PRESALE OWNER OR ADMIN");
        _;
    }

    modifier onlyCaller() {
        require(CALLER == msg.sender, "NOT PRESALE CALLER");
        _;
    }

    modifier onlyValidAccess(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) {
        if (STATUS.WHITELIST_ONLY) {
            require(
                isValidAccessMsg(msg.sender, _v, _r, _s),
                "NOT WHITELISTED"
            );
        }
        _;
    }

    function isValidAccessMsg(
        address _addr,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(address(this), _addr));
        return
            DAOLAUNCH_DEV !=
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
                ),
                _v,
                _r,
                _s
            );
    }

    function presaleStatus() public view returns (uint256) {
        if (
            (block.timestamp > PRESALE_INFO.END_TIME) &&
            (STATUS.TOTAL_BASE_COLLECTED < PRESALE_INFO.SOFTCAP)
        ) {
            return 3; // FAILED - softcap not met by end block
        }
        if (STATUS.TOTAL_BASE_COLLECTED >= PRESALE_INFO.HARDCAP) {
            return 2; // SUCCESS - hardcap met
        }
        if (
            (block.timestamp > PRESALE_INFO.END_TIME) &&
            (STATUS.TOTAL_BASE_COLLECTED >= PRESALE_INFO.SOFTCAP)
        ) {
            return 2; // SUCCESS - endblock and soft cap reached
        }
        if (
            (block.timestamp >= PRESALE_INFO.START_TIME) &&
            (block.timestamp <= PRESALE_INFO.END_TIME)
        ) {
            return 1; // ACTIVE - deposits enabled
        }
        return 0; // QUED - awaiting start block
    }

    // accepts msg.value for eth or _amount for ERC20 tokens
    function userDeposit(
        uint256 _amount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable onlyValidAccess(_v, _r, _s) nonReentrant {
        require(presaleStatus() == 1, "NOT ACTIVE"); // ACTIVE
        BuyerInfo storage buyer = BUYERS[msg.sender];
        uint256 amount_in = PRESALE_INFO.PRESALE_IN_ETH ? msg.value : _amount;
        uint256 real_amount_in = amount_in;
        uint256 fee = 0;
        
        if (!STATUS.WHITELIST_ONLY) {
            real_amount_in = real_amount_in * (1000 - PERCENT_FEE)/ 1000;
            fee = amount_in - real_amount_in;
        }
        require(
            real_amount_in >= PRESALE_INFO.MIN_SPEND_PER_BUYER,
            "NOT ENOUGH VALUE"
        );
        uint256 allowance = PRESALE_INFO.MAX_SPEND_PER_BUYER -
            buyer.baseDeposited;
        uint256 remaining = PRESALE_INFO.HARDCAP - STATUS.TOTAL_BASE_COLLECTED;
        allowance = allowance > remaining ? remaining : allowance;
        if (real_amount_in > allowance) {
            real_amount_in = allowance;
        }
        // uint256 tokensSold = (real_amount_in * PRESALE_INFO.TOKEN_PRICE) /
        //     (10**uint256(PRESALE_INFO.B_TOKEN.decimals()));
        // From test user set decimals;

        uint256 tokensSold = (real_amount_in * PRESALE_INFO.TOKEN_PRICE);
        require(tokensSold > 0, "ZERO TOKENS");
        if (buyer.baseDeposited == 0) {
            STATUS.NUM_BUYERS++;
        }
        buyer.baseDeposited += real_amount_in + fee;
        buyer.tokensOwed += tokensSold;
        STATUS.TOTAL_BASE_COLLECTED += real_amount_in;
        STATUS.TOTAL_TOKENS_SOLD += tokensSold;
        USER_FEES[msg.sender] += fee;
        TOTAL_FEE += fee;

        //return unused ETH
        if (PRESALE_INFO.PRESALE_IN_ETH && real_amount_in + fee < msg.value) {
            payable(msg.sender).transfer(msg.value - real_amount_in - fee);
        }
        // deduct non ETH token from user
        if (!PRESALE_INFO.PRESALE_IN_ETH) {
            TransferHelper.safeTransferFrom(
                address(PRESALE_INFO.B_TOKEN),
                msg.sender,
                address(this),
                real_amount_in + fee
            );
        }
    }

    // withdraw presale tokens
    // percentile withdrawls allows fee on transfer or rebasing tokens to still work
    function userWithdrawTokens() external nonReentrant {
        require(presaleStatus() == 2, "NOT SUCCESS"); // SUCCESS
        require(
            block.timestamp >= VESTING_PERIOD.firstDistributionType,
            "NOT NOW"
        );
        require(
            STATUS.TOTAL_TOKENS_SOLD - STATUS.TOTAL_TOKENS_WITHDRAWN > 0,
            "ALL TOKEN HAS BEEN WITHDRAWN"
        );
        require(PRESALE_INFO.ADD_LP != 2, "OFF-CHAIN MODE");

        BuyerInfo storage buyer = BUYERS[msg.sender];
        require(!buyer.isWithdrawnBase, "NOTHING TO CLAIM");

        uint256 rateWithdrawAfter;
        uint256 currentTime;
        if (block.timestamp > VESTING_PERIOD.maxPeriod) {
            currentTime = VESTING_PERIOD.maxPeriod;
        } else {
            currentTime = block.timestamp;
        }
        uint256 tokensOwed = buyer.tokensOwed;
        if (VESTING_PERIOD.firstUnlockRate == 100) {
            require(
                buyer.totalTokenWithdraw != tokensOwed,
                "Already withdraw all"
            );
            rateWithdrawAfter = 100;
        } else {
            uint256 spentCycles = (currentTime -
                VESTING_PERIOD.firstDistributionType) /
                VESTING_PERIOD.distributionInterval; // (m' - m0)/k
            if (buyer.lastWithdraw == 0) {
                rateWithdrawAfter =
                    spentCycles *
                    VESTING_PERIOD.unlockRateEachTime +
                    VESTING_PERIOD.firstUnlockRate; //x + spentCycles*y
            } else {
                uint256 lastSpentCycles = (buyer.lastWithdraw -
                    VESTING_PERIOD.firstDistributionType) /
                    VESTING_PERIOD.distributionInterval; // (LD - M0)/k
                rateWithdrawAfter =
                    (spentCycles - lastSpentCycles) *
                    VESTING_PERIOD.unlockRateEachTime; //(spentCycles - lastSpentCycles)*y
                require(rateWithdrawAfter > 0, "INVALID MOMENT"); // SUCCESS
            }
        }
        buyer.lastWithdraw = currentTime;
        uint256 amountWithdraw = (tokensOwed * rateWithdrawAfter) / 100;

        if (buyer.totalTokenWithdraw + amountWithdraw > buyer.tokensOwed) {
            amountWithdraw = buyer.tokensOwed - buyer.totalTokenWithdraw;
        }

        STATUS.TOTAL_TOKENS_WITHDRAWN += amountWithdraw;
        buyer.totalTokenWithdraw += amountWithdraw; // update total token withdraw of buyer address
        TransferHelper.safeTransfer(
            address(PRESALE_INFO.S_TOKEN),
            msg.sender,
            amountWithdraw
        );
    }

    // // on presale failure
    // // percentile withdrawls allows fee on transfer or rebasing tokens to still work
    function userWithdrawBaseTokens() external nonReentrant {
        require(presaleStatus() == 3, "NOT FAILED"); // FAILED
        BuyerInfo storage buyer = BUYERS[msg.sender];
        require(!buyer.isWithdrawnBase, "NOTHING TO REFUND");

        STATUS.TOTAL_BASE_WITHDRAWN += buyer.baseDeposited;
        TransferHelper.safeTransferBaseToken(
            address(PRESALE_INFO.B_TOKEN),
            payable(msg.sender),
            buyer.baseDeposited,
            !PRESALE_INFO.PRESALE_IN_ETH
        );
        buyer.isWithdrawnBase = true;
    }

    // // on presale failure
    // // allows the owner to withdraw the tokens they sent for presale & initial liquidity
    function ownerRefundTokens() external onlyPresaleOwner {
        require(presaleStatus() == 3, "NOT FAILED"); // FAILED
        require(!STATUS.IS_OWNER_WITHDRAWN, "NOTHING TO WITHDRAW");
        TransferHelper.safeTransfer(
            address(PRESALE_INFO.S_TOKEN),
            PRESALE_INFO.PRESALE_OWNER,
            PRESALE_INFO.S_TOKEN.balanceOf(address(this))
        );
        STATUS.IS_OWNER_WITHDRAWN = true;

        // send eth fee to owner
        PRESALE_INFO.PRESALE_OWNER.transfer(
            PRESALE_SETTINGS.getEthCreationFee()
        );
    }

    // // on presale success, this is the final step to end the presale, lock liquidity and enable withdrawls of the sale token.
    // // This function does not use percentile distribution. Rebasing mechanisms, fee on transfers, or any deflationary logic
    // // are not taken into account at this stage to ensure stated liquidity is locked and the pool is initialised according to
    // // the presale parameters and fixed prices.

    // function listOnUniswap() external onlyCaller {
    //     require(PRESALE_INFO.UNISWAP_LISTING_TIME > 0, "NO LISTING TIME");
    //     require(block.timestamp > PRESALE_INFO.UNISWAP_LISTING_TIME + 1 days, "EARLY TO CALL");
    //     // require(
    //     //     block.timestamp >= PRESALE_INFO.UNISWAP_LISTING_TIME,
    //     //     "Call listOnUniswap too early"
    //     // );
    //     require(presaleStatus() == 2, "NOT SUCCESS"); // SUCCESS
    //     require(!STATUS.IS_TRANSFERED_FEE, "TRANSFERED FEE");
    //     // require(PRESALE_INFO.LIQUIDITY_PERCENT > 0, "LIQUIDITY_PERCENT = 0");

    //     if (PRESALE_INFO.ADD_LP == 2) {
    //         // off-chain mode
    //         // send all to DAOLaunch, remaining listing fee to presale owner

    //         // send all base token
    //         TransferHelper.safeTransferBaseToken(
    //             address(PRESALE_INFO.B_TOKEN),
    //             PRESALE_FEE_INFO.BASE_FEE_ADDRESS,
    //             STATUS.TOTAL_BASE_COLLECTED + TOTAL_FEE - TOTAL_TOKENS_REFUNDED - TOTAL_FEES_REFUNDED,
    //             !PRESALE_INFO.PRESALE_IN_ETH
    //         );

    //         // send all token
    //         uint256 tokenBalance = PRESALE_INFO.S_TOKEN.balanceOf(address(this));
    //         TransferHelper.safeTransfer(
    //             address(PRESALE_INFO.S_TOKEN),
    //             PRESALE_FEE_INFO.TOKEN_FEE_ADDRESS,
    //             tokenBalance
    //         );

    //         // send transaction fee
    //         uint256 txFee = tx.gasprice * GAS_LIMIT.transferPresaleOwner;
    //         require(txFee <= PRESALE_SETTINGS.getEthCreationFee());
    //         CALLER.transfer(txFee);
    //         PRESALE_INFO.PRESALE_OWNER.transfer(
    //             PRESALE_SETTINGS.getEthCreationFee() - txFee
    //         );
    //         return;
    //     }

    //     uint256 DAOLaunchBaseFee = ((STATUS.TOTAL_BASE_COLLECTED - TOTAL_TOKENS_REFUNDED) *
    //         PRESALE_FEE_INFO.DAOLAUNCH_BASE_FEE) / 1000;
    //     // base token liquidity
    //     uint256 baseLiquidity = (((STATUS.TOTAL_BASE_COLLECTED - TOTAL_TOKENS_REFUNDED) -
    //         DAOLaunchBaseFee) * PRESALE_INFO.LIQUIDITY_PERCENT) / 1000;
    //     if (
    //         PRESALE_INFO.ADD_LP == 0 &&
    //         baseLiquidity > 0 &&
    //         PRESALE_INFO.PRESALE_IN_ETH
    //     ) {
    //         WETH.deposit{value: baseLiquidity}();
    //     }

    //     if (PRESALE_INFO.ADD_LP == 0 && baseLiquidity > 0) {
    //         TransferHelper.safeApprove(
    //             address(PRESALE_INFO.B_TOKEN),
    //             address(PRESALE_LOCK_FORWARDER),
    //             baseLiquidity
    //         );
    //     }

    //     // sale token liquidity
    //     uint256 tokenLiquidity = (baseLiquidity * PRESALE_INFO.LISTING_RATE) /
    //         (10**uint256(PRESALE_INFO.B_TOKEN.decimals()));

    //     // transfer fees
    //     uint256 DAOLaunchTokenFee = (STATUS.TOTAL_TOKENS_SOLD *
    //         PRESALE_FEE_INFO.DAOLAUNCH_TOKEN_FEE) / 1000;
    //     if (DAOLaunchBaseFee + TOTAL_FEE > 0) {
    //         TransferHelper.safeTransferBaseToken(
    //             address(PRESALE_INFO.B_TOKEN),
    //             PRESALE_FEE_INFO.BASE_FEE_ADDRESS,
    //             DAOLaunchBaseFee + TOTAL_FEE,
    //             !PRESALE_INFO.PRESALE_IN_ETH
    //         );
    //     }
    //     if (DAOLaunchTokenFee > 0) {
    //         TransferHelper.safeTransfer(
    //             address(PRESALE_INFO.S_TOKEN),
    //             PRESALE_FEE_INFO.TOKEN_FEE_ADDRESS,
    //             DAOLaunchTokenFee
    //         );
    //     }
    //     STATUS.IS_TRANSFERED_FEE = true;

    //     // if use escrow or percent = 0%
    //     if (PRESALE_INFO.ADD_LP == 1 || baseLiquidity == 0) {
    //         // transfer fee to DAOLaunch
    //         uint256 txFee = tx.gasprice * GAS_LIMIT.transferPresaleOwner;
    //         require(txFee <= PRESALE_SETTINGS.getEthCreationFee());

    //         if (baseLiquidity == 0) {
    //             // send fee to project owner
    //             PRESALE_INFO.PRESALE_OWNER.transfer(
    //                 PRESALE_SETTINGS.getEthCreationFee() - txFee
    //             );
    //         } else {
    //             // send fee to DAOLaunch
    //             PRESALE_FEE_INFO.BASE_FEE_ADDRESS.transfer(
    //                 PRESALE_SETTINGS.getEthCreationFee() - txFee
    //             );
    //         }

    //         // send transaction fee
    //         CALLER.transfer(txFee);
    //     } else {
    //         // transfer fee to DAOLaunch
    //         uint256 txFee = tx.gasprice * GAS_LIMIT.listOnUniswap;
    //         require(txFee <= PRESALE_SETTINGS.getEthCreationFee());

    //         // send fee to DAOLaunch
    //         PRESALE_FEE_INFO.BASE_FEE_ADDRESS.transfer(
    //             PRESALE_SETTINGS.getEthCreationFee() - txFee
    //         );

    //         // send transaction fee
    //         CALLER.transfer(txFee);
    //     }

    //     if (PRESALE_INFO.ADD_LP == 1) {
    //         // send liquidity to DAOLaunch
    //         TransferHelper.safeTransferBaseToken(
    //             address(PRESALE_INFO.B_TOKEN),
    //             PRESALE_FEE_INFO.BASE_FEE_ADDRESS,
    //             baseLiquidity,
    //             !PRESALE_INFO.PRESALE_IN_ETH
    //         );
    //         TransferHelper.safeTransfer(
    //             address(PRESALE_INFO.S_TOKEN),
    //             PRESALE_FEE_INFO.BASE_FEE_ADDRESS,
    //             tokenLiquidity
    //         );
    //     } else {
    //         if (baseLiquidity > 0) {
    //             // Fail the presale if the pair exists and contains presale token liquidity
    //             if (
    //                 PRESALE_LOCK_FORWARDER.uniswapPairIsInitialised(
    //                     address(PRESALE_INFO.S_TOKEN),
    //                     address(PRESALE_INFO.B_TOKEN)
    //                 )
    //             ) {
    //                 STATUS.LIST_ON_UNISWAP = true;

    //                 TransferHelper.safeTransferBaseToken(
    //                     address(PRESALE_INFO.B_TOKEN),
    //                     PRESALE_INFO.PRESALE_OWNER,
    //                     baseLiquidity,
    //                     !PRESALE_INFO.PRESALE_IN_ETH
    //                 );
    //                 TransferHelper.safeTransfer(
    //                     address(PRESALE_INFO.S_TOKEN),
    //                     PRESALE_INFO.PRESALE_OWNER,
    //                     tokenLiquidity
    //                 );
    //                 return;
    //             }

    //             TransferHelper.safeApprove(
    //                 address(PRESALE_INFO.S_TOKEN),
    //                 address(PRESALE_LOCK_FORWARDER),
    //                 tokenLiquidity
    //             );
    //             PRESALE_LOCK_FORWARDER.lockLiquidity(
    //                 PRESALE_INFO.B_TOKEN,
    //                 PRESALE_INFO.S_TOKEN,
    //                 baseLiquidity,
    //                 tokenLiquidity,
    //                 block.timestamp + PRESALE_INFO.LOCK_PERIOD,
    //                 PRESALE_INFO.PRESALE_OWNER
    //             );
    //         }
    //     }
    //     STATUS.LIST_ON_UNISWAP = true;
    // }

    // function ownerWithdrawTokens() external nonReentrant onlyPresaleOwner {
    //     require(!STATUS.IS_OWNER_WITHDRAWN, "GENERATION COMPLETE");
    //     require(presaleStatus() == 2, "NOT SUCCESS"); // SUCCESS
    //     require(PRESALE_INFO.ADD_LP != 2, "OFF-CHAIN MODE");
    //     require(PRESALE_INFO.UNISWAP_LISTING_TIME > 0, "NO LISTING TIME");
    //     require(block.timestamp > PRESALE_INFO.UNISWAP_LISTING_TIME + 1 days, "EARLY TO CALL");

    //     uint256 DAOLaunchBaseFee = ((STATUS.TOTAL_BASE_COLLECTED - TOTAL_TOKENS_REFUNDED) *
    //         PRESALE_FEE_INFO.DAOLAUNCH_BASE_FEE) / 1000;
    //     uint256 baseLiquidity = (((STATUS.TOTAL_BASE_COLLECTED - TOTAL_TOKENS_REFUNDED) -
    //         DAOLaunchBaseFee) * PRESALE_INFO.LIQUIDITY_PERCENT) / 1000;
    //     uint256 DAOLaunchTokenFee = (STATUS.TOTAL_TOKENS_SOLD *
    //         PRESALE_FEE_INFO.DAOLAUNCH_TOKEN_FEE) / 1000;
    //     uint256 tokenLiquidity = (baseLiquidity * PRESALE_INFO.LISTING_RATE) /
    //         (10**uint256(PRESALE_INFO.B_TOKEN.decimals()));

    //     // send remain unsold tokens to presale owner
    //     uint256 remainingSBalance = PRESALE_INFO.S_TOKEN.balanceOf(
    //         address(this)
    //     ) +
    //         STATUS.TOTAL_TOKENS_WITHDRAWN -
    //         STATUS.TOTAL_TOKENS_SOLD;

    //     // send remaining base tokens to presale owner
    //     uint256 remainingBaseBalance = PRESALE_INFO.PRESALE_IN_ETH
    //         ? address(this).balance
    //         : PRESALE_INFO.B_TOKEN.balanceOf(address(this));
    //     if (!STATUS.IS_TRANSFERED_FEE) {
    //         remainingBaseBalance -= DAOLaunchBaseFee;
    //         remainingSBalance -= DAOLaunchTokenFee;
    //         remainingBaseBalance -= TOTAL_FEE;
    //     }
    //     if (!STATUS.LIST_ON_UNISWAP) {
    //         if (PRESALE_INFO.PRESALE_IN_ETH) {
    //             remainingBaseBalance -=
    //                 baseLiquidity +
    //                 PRESALE_SETTINGS.getEthCreationFee();
    //         } else {
    //             remainingBaseBalance -= baseLiquidity;
    //         }
    //         remainingSBalance -= tokenLiquidity;
    //     }

    //     // add refund
    //     uint256 tokenRefunded = TOTAL_TOKENS_REFUNDED * PRESALE_INFO.TOKEN_PRICE / (10**uint256(PRESALE_INFO.B_TOKEN.decimals()));
    //     remainingSBalance += tokenRefunded;

    //     if (remainingSBalance > 0) {
    //         TransferHelper.safeTransfer(
    //             address(PRESALE_INFO.S_TOKEN),
    //             PRESALE_INFO.PRESALE_OWNER,
    //             remainingSBalance
    //         );
    //     }

    //     TransferHelper.safeTransferBaseToken(
    //         address(PRESALE_INFO.B_TOKEN),
    //         PRESALE_INFO.PRESALE_OWNER,
    //         remainingBaseBalance,
    //         !PRESALE_INFO.PRESALE_IN_ETH
    //     );
    //     STATUS.IS_OWNER_WITHDRAWN = true;
    // }

    // function userRefundTokens() external nonReentrant {
    //     require(block.timestamp > PRESALE_INFO.UNISWAP_LISTING_TIME, "EARLY TO CALL");
    //     require(block.timestamp < PRESALE_INFO.UNISWAP_LISTING_TIME + 1 days, "LATE TO CALL");
    //     require(presaleStatus() == 2, "NOT SUCCESS"); // SUCCESS
    //     require(PRESALE_INFO.UNISWAP_LISTING_TIME > 0, "NO LISTING TIME");

    //     BuyerInfo storage buyer = BUYERS[msg.sender];
    //     require(!buyer.isWithdrawnBase, "NOTHING TO REFUND");
    //     require(buyer.totalTokenWithdraw == 0, "CANNOT REFUND");

    //     TOTAL_TOKENS_REFUNDED += buyer.baseDeposited - USER_FEES[msg.sender];
    //     TOTAL_FEES_REFUNDED += USER_FEES[msg.sender];
    //     TransferHelper.safeTransferBaseToken(
    //         address(PRESALE_INFO.B_TOKEN),
    //         payable(msg.sender),
    //         buyer.baseDeposited,
    //         !PRESALE_INFO.PRESALE_IN_ETH
    //     );
    //     buyer.isWithdrawnBase = true;
    // }

    // function updateGasLimit(
    //     uint256 _transferPresaleOwner,
    //     uint256 _listOnUniswap
    // ) external {
    //     require(msg.sender == DAOLAUNCH_DEV, "INVALID CALLER");
    //     GAS_LIMIT.transferPresaleOwner = _transferPresaleOwner;
    //     GAS_LIMIT.listOnUniswap = _listOnUniswap;
    // }

    // function updateMaxSpendLimit(uint256 _maxSpend) external onlyPresaleOwnerOrAdmin {
    //     PRESALE_INFO.MAX_SPEND_PER_BUYER = _maxSpend;
    // }

    // // postpone or bring a presale forward, this will only work when a presale is inactive.
    // // i.e. current start block > block.timestamp
    // function updateBlocks(uint256 _startTime, uint256 _endTime)
    //     external
    //     onlyPresaleOwnerOrAdmin
    // {
    //     require(PRESALE_INFO.START_TIME > block.timestamp);
    //     require(_endTime - _startTime > 0);
    //     PRESALE_INFO.START_TIME = _startTime;
    //     PRESALE_INFO.END_TIME = _endTime;
    // }

    // // editable at any stage of the presale
    // function setWhitelistFlag(bool _flag) external onlyPresaleOwnerOrAdmin {
    //     STATUS.WHITELIST_ONLY = _flag;
    // }

    // function updateAdmin(address _adminAddr, bool _flag) external onlyAdmin {
    //     require(_adminAddr != address(0), "INVALID ADDRESS");
    //     admins[_adminAddr] = _flag;
    // }

    // // if uniswap listing fails, call this function to release eth
    // function finalize() external {
    //     require(msg.sender == DAOLAUNCH_DEV, "INVALID CALLER");

    //     uint256 remainingBBalance;
    //     if (!PRESALE_INFO.PRESALE_IN_ETH) {
    //         remainingBBalance = PRESALE_INFO.B_TOKEN.balanceOf(
    //             address(this)
    //         );
    //     } else {
    //         remainingBBalance = address(this).balance;
    //     }
    //     TransferHelper.safeTransferBaseToken(
    //         address(PRESALE_INFO.B_TOKEN),
    //         PRESALE_FEE_INFO.BASE_FEE_ADDRESS,
    //         remainingBBalance,
    //         !PRESALE_INFO.PRESALE_IN_ETH
    //     );

    //     uint256 remainingSBalance = PRESALE_INFO.S_TOKEN.balanceOf(
    //         address(this)
    //     );
    //     TransferHelper.safeTransfer(
    //         address(PRESALE_INFO.S_TOKEN),
    //         PRESALE_FEE_INFO.BASE_FEE_ADDRESS,
    //         remainingSBalance
    //     );
    //     selfdestruct(PRESALE_FEE_INFO.BASE_FEE_ADDRESS);
    // }

    // // editable at any stage of the presale
    // function changePresaleType(bool _flag, uint256 _maxSpend) external onlyAdmin {
    //     STATUS.WHITELIST_ONLY = _flag;
    //     PRESALE_INFO.MAX_SPEND_PER_BUYER = _maxSpend;
    // }

    // function updateListingTime(uint256 _listOnUniswap) external onlyAdmin {
    //     require(_listOnUniswap > PRESALE_INFO.END_TIME, "INVALID TIME");
    //     PRESALE_INFO.UNISWAP_LISTING_TIME = _listOnUniswap;
    // }
}
