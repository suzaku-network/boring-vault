// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import {DeployArcticArchitecture, ERC20, Deployer} from "script/ArchitectureDeployments/DeployArcticArchitecture.sol";
import {AddressToBytes32Lib} from "src/helper/AddressToBytes32Lib.sol";
import {SepoliaAddresses} from "test/resources/SepoliaAddresses.sol";

// Import Decoder and Sanitizer to deploy.
import {SepoliaSuzakuDecoderAndSanitzer} from "src/base/DecodersAndSanitizers/SepoliaSuzakuDecoderAndSanitzer.sol";

/**
 *  source .env && forge script script/ArchitectureDeployments/sepolia/DeploySepoliaBTCb.s.sol:DeploySepoliaVaultScript --with-gas-price 10000000000 --slow --broadcast --etherscan-api-key $ETHERSCAN_KEY --verify
 * @dev Optionally can change `--with-gas-price` to something more reasonable
 */
contract DeploySepoliaBTCb is DeployArcticArchitecture, SepoliaAddresses {
    using AddressToBytes32Lib for address;

    uint256 public privateKey;

    // Deployment parameters
    string public boringVaultName = "BTCb Vault";
    string public boringVaultSymbol = "suzLRTBTCb";
    uint8 public boringVaultDecimals = 18;
    address public owner = dev0Address;

    function setUp() external {
        privateKey = vm.envUint("ETHERFI_LIQUID_DEPLOYER");
        vm.createSelectFork("sepolia");
    }

    function run() external {
        // Configure the deployment.
        configureDeployment.deployContracts = true;
        configureDeployment.setupRoles = true;
        configureDeployment.setupDepositAssets = true;
        configureDeployment.setupWithdrawAssets = true;
        configureDeployment.finishSetup = true;
        configureDeployment.setupTestUser = true;
        configureDeployment.saveDeploymentDetails = true;
        configureDeployment.deployerAddress = deployerAddress;
        configureDeployment.balancerVault = balancerVault;
        configureDeployment.WETH = address(WETH);
        configureDeployment.initiatePullFundsFromVault = true;

        // Save deployer.
        deployer = Deployer(configureDeployment.deployerAddress);

        // Define names to determine where contracts are deployed.
        names.rolesAuthority = SepoliaVaultRolesAuthorityName;
        names.lens = ArcticArchitectureLensName;
        names.boringVault = SepoliaVaultName;
        names.manager = SepoliaVaultManagerName;
        names.accountant = SepoliaVaultAccountantName;
        names.teller = SepoliaVaultTellerName;
        names.rawDataDecoderAndSanitizer = SepoliaVaultDecoderAndSanitizerName;
        names.delayedWithdrawer = SepoliaVaultDelayedWithdrawer;

        // Define Accountant Parameters.
        accountantParameters.payoutAddress = liquidPayoutAddress;
        accountantParameters.base = BTCb;
        // Decimals are in terms of `base`.
        accountantParameters.startingExchangeRate = 1e18;
        //  4 decimals
        accountantParameters.managementFee = 0.02e4;
        accountantParameters.performanceFee = 0;
        accountantParameters.allowedExchangeRateChangeLower = 0.995e4;
        accountantParameters.allowedExchangeRateChangeUpper = 1.005e4;
        // Minimum time(in seconds) to pass between updated without triggering a pause.
        accountantParameters.minimumUpateDelayInSeconds = 1 days / 4;

        // Define Decoder and Sanitizer deployment details.
        bytes memory creationCode = type(SepoliaSuzakuDecoderAndSanitzer)
            .creationCode;
        bytes memory constructorArgs = abi.encode(
            deployer.getAddress(names.boringVault),
            uniswapV3NonFungiblePositionManager
        );

        // Setup extra deposit assets.
        // none

        // Setup withdraw assets.
        // none

        withdrawAssets.push(
            WithdrawAsset({
                asset: BTCb,
                withdrawDelay: 300 seconds,
                completionWindow: 1500 seconds,
                withdrawFee: 0,
                maxLoss: 0.01e4
            })
        );

        bool allowPublicDeposits = true;
        bool allowPublicWithdraws = true;
        uint64 shareLockPeriod = 0;
        address delayedWithdrawFeeAddress = liquidPayoutAddress;

        vm.startBroadcast(privateKey);

        _deploy(
            "SepoliaDeployment.json",
            owner,
            boringVaultName,
            boringVaultSymbol,
            boringVaultDecimals,
            creationCode,
            constructorArgs,
            delayedWithdrawFeeAddress,
            allowPublicDeposits,
            allowPublicWithdraws,
            shareLockPeriod,
            dev0Address
        );

        vm.stopBroadcast();
    }
}
