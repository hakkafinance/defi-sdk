// import displayToken from './helpers/displayToken';
// import expectRevert from './helpers/expectRevert';
import convertToShare from '../helpers/convertToShare';

const ACTION_DEPOSIT = 1;
const ACTION_WITHDRAW = 2;
const AMOUNT_RELATIVE = 1;
const AMOUNT_ABSOLUTE = 2;
const EMPTY_BYTES = '0x';
const ADAPTER_ASSET = 0;
// const ADAPTER_DEBT = 1;
// const ADAPTER_EXCHANGE = 2;

const ZERO = '0x0000000000000000000000000000000000000000';

const AdapterRegistry = artifacts.require('./AdapterRegistry');
const InteractiveAdapter = artifacts.require('./WethInteractiveAdapter');
const Logic = artifacts.require('./Logic');
const Router = artifacts.require('./Router');
const ERC20 = artifacts.require('./ERC20');

contract('Weth interactive adapter', () => {
  const wethAddress = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
  const ethAddress = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';

  let accounts;
  let logic;
  let tokenSpender;
  let adapterRegistry;
  let protocolAdapterAddress;
  let WETH;

  describe('ETH <-> WETH exchange', () => {
    beforeEach(async () => {
      accounts = await web3.eth.getAccounts();
      await InteractiveAdapter.new({ from: accounts[0] })
        .then((result) => {
          protocolAdapterAddress = result.address;
        });
      await AdapterRegistry.new({ from: accounts[0] })
        .then((result) => {
          adapterRegistry = result.contract;
        });
      await adapterRegistry.methods.addProtocols(
        [web3.utils.toHex('Weth')],
        [[
          'Mock Protocol Name',
          'Mock protocol description',
          'Mock website',
          'Mock icon',
          '0',
        ]],
        [[
          protocolAdapterAddress,
        ]],
        [[[]]],
      )
        .send({
          from: accounts[0],
          gas: '1000000',
        });
      await Logic.new(
        adapterRegistry.options.address,
        { from: accounts[0] },
      )
        .then((result) => {
          logic = result.contract;
        });
      await Router.new(
        logic.options.address,
        { from: accounts[0] },
      )
        .then((result) => {
          tokenSpender = result.contract;
        });
      await ERC20.at(wethAddress)
        .then((result) => {
          WETH = result.contract;
        });
    });

    it('should be correct one-side exchange deposit-like', async () => {
      await WETH.methods['balanceOf(address)'](accounts[0])
        .call()
        .then((result) => {
          console.log(`weth amount before is ${web3.utils.fromWei(result, 'ether')}`);
        });
      await web3.eth.getBalance(accounts[0])
        .then((result) => {
          console.log(`eth amount before is  ${web3.utils.fromWei(result, 'ether')}`);
        });
      await tokenSpender.methods.startExecution(
        [
          [
            ACTION_DEPOSIT,
            web3.utils.toHex('Weth'),
            ADAPTER_ASSET,
            [ethAddress],
            [web3.utils.toWei('1', 'ether')],
            [AMOUNT_ABSOLUTE],
            EMPTY_BYTES,
          ],
        ],
        [],
        [
          [wethAddress, web3.utils.toWei('1', 'ether')],
        ],
      )
        .send({
          gas: 10000000,
          from: accounts[0],
          value: web3.utils.toWei('1', 'ether'),
        })
        .then((receipt) => {
          console.log(`called tokenSpender for ${receipt.cumulativeGasUsed} gas`);
        });
      await WETH.methods['balanceOf(address)'](accounts[0])
        .call()
        .then((result) => {
          console.log(`weth amount after is ${web3.utils.fromWei(result, 'ether')}`);
        });
      await web3.eth.getBalance(accounts[0])
        .then((result) => {
          console.log(`eth amount after is  ${web3.utils.fromWei(result, 'ether')}`);
        });
      await WETH.methods['balanceOf(address)'](logic.options.address)
        .call()
        .then((result) => {
          assert.equal(result, 0);
        });
      await web3.eth.getBalance(logic.options.address)
        .then((result) => {
          assert.equal(result, 0);
        });
    });

    it('should be correct reverse exchange deposit-like', async () => {
      let wethAmount;
      await WETH.methods['balanceOf(address)'](accounts[0])
        .call()
        .then((result) => {
          console.log(`weth amount before is ${web3.utils.fromWei(result, 'ether')}`);
          wethAmount = result;
        });
      await WETH.methods.approve(tokenSpender.options.address, wethAmount.toString())
        .send({
          from: accounts[0],
          gas: 1000000,
        });
      await web3.eth.getBalance(accounts[0])
        .then((result) => {
          console.log(`eth amount before is  ${web3.utils.fromWei(result, 'ether')}`);
        });
      console.log('calling tokenSpender with action...');
      await tokenSpender.methods.startExecution(
        [
          [
            ACTION_WITHDRAW,
            web3.utils.toHex('Weth'),
            ADAPTER_ASSET,
            [wethAddress],
            [convertToShare(1)],
            [AMOUNT_RELATIVE],
            EMPTY_BYTES,
          ],
        ],
        [
          [wethAddress, convertToShare(1), AMOUNT_RELATIVE, 0, ZERO],
        ],
        [
          [ethAddress, web3.utils.toWei('1', 'ether')],
        ],
      )
        .send({
          gas: 10000000,
          from: accounts[0],
          value: web3.utils.toWei('1', 'ether'),
        });
      await WETH.methods['balanceOf(address)'](accounts[0])
        .call()
        .then((result) => {
          console.log(`weth amount after is    ${web3.utils.fromWei(result, 'ether')}`);
        });
      await web3.eth.getBalance(accounts[0])
        .then((result) => {
          console.log(`eth amount after is  ${web3.utils.fromWei(result, 'ether')}`);
        });
      await WETH.methods['balanceOf(address)'](logic.options.address)
        .call()
        .then((result) => {
          assert.equal(result, 0);
        });
      await web3.eth.getBalance(logic.options.address)
        .then((result) => {
          assert.equal(result, 0);
        });
    });
  });
});
