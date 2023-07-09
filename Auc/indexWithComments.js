import React, { Component } from 'react'
import { ethers } from 'ethers'

import { ConnectWallet } from '../components/ConnectWallet'
import { WaitingForTransactionMessage } from '../components/WaitingForTransactionMessage'
import { TransactionErrorMessage } from '../components/TransactionErrorMessage'

import auctionAddress from '../contracts/DutchAuction-contract-address.json'
import auctionArtifact from '../contracts/DutchAuction.json'

// import { setIntervalAsync, clearIntervalAsync } from 'set-interval-async'

const HARDHAT_NETWORK_ID = '1337'
const ERROR_CODE_TX_REJECTED_BY_USER = 4001 // если пользователь отправил деньги, но отменил их через metamask, то выдаст номер данной ошибки (4001)

// Работает через раз, иногда без ошибок, иногда с одной ошибкой, так что лучше использовать именно index.js (это без файл без комментариев)
export default class extends Component {
  constructor(props) {
    super(props)

    this.initialState = {
      selectedAccount: null,
      txBeingSent: null, // отправляется ли сейчас какая-то транзакция
      networkError: null,
      transactionError: null,
      balance: null,
      currentPrice: null,
      stopped: false,
    }

    this.state = this.initialState
  }

  _connectWallet = async () => {
    // если метамаска не обнаружено
    if(window.ethereum === undefined) {
      this.setState({
        networkError: 'Please install Metamask!'
      })
      return
    }

    // пользователь выбирает адрес с помощью которого он будет работать
    const [selectedAddress] = await window.ethereum.request({
      method: 'eth_requestAccounts'
    })

    // проверка сети hardhat
    if(!this._checkNetwork()) { return }

    this._initialize(selectedAddress)

    // если пользователь сменил аккаунт
    window.ethereum.on('accountsChanged', ([newAddress]) => {
      if(newAddress === undefined) {
        return this._resetState()
      }

      this._initialize(newAddress)
    })

    // если пользователь сменил сеть
    window.ethereum.on('chainChanged', ([networkId]) => {
      this._resetState()
    })
  }

  async _initialize(selectedAddress) {
    // то через что мы работаем с блокчейном, то есть это metamask
    this._provider = new ethers.providers.Web3Provider(window.ethereum)

    // подключение к контракту
    this._auction = new ethers.Contract(
      auctionAddress.DutchAuction, // адрес смартконтракта
      auctionArtifact.abi, // интерфейс контракта abi
      this._provider.getSigner(0) // то через чье имя мы подключаемся, то есть берем наш выбранный аккаунт в metamask
    )

    this.setState({
      selectedAccount: selectedAddress
    }, async () => {
      await this.updateBalance()
    })

    if(await this.updateStopped()) { return }

    this.startingPrice = await this._auction.startingPrice()
    this.startAt = await this._auction.startAt() // возвращается в секундах
    this.discountRate = await this._auction.discountRate()

    // для работы с блокчейном
    // this.chechPriceInterval = setIntervalAsync(async() => {
    //   this.setState({
    //     currentPrice: ethers.utils.formatEther( await this._auction.getPrice() )
    //   })
    // }, 1000)

    // для имитации изменения цены (без обращения к блокчейну)
    this.checkPriceInterval = setInterval(() => {
      // bignumbers поддерживают математ оперции, но только через функции такие как "sub - минус", "mul - умнож"
      const elapsed = ethers.BigNumber.from(
        Math.floor(Date.now() / 1000) // тк date.now() возвращается в миллисек
      ).sub(this.startAt)
      const discount = this.discountRate.mul(elapsed)
      const newPrice = this.startingPrice.sub(discount)
      this.setState({
        currentPrice: ethers.utils.formatEther(newPrice)
      })
    }, 1000)

    // работа с событиями
    // const startBlockNumber = await this._provider.getBlockNumber()
    // this._auction.on('Bought', (...args) => {
    //   // могут быть проблемы с событиями и выдаваться старые собития
    //   const event = args[args.length - 1] // самый последний аргумент это будет всё о самом событии
    //   if(event.blockNumber <= startBlockNumber) return // чтобы не обрабатывать блоки которые были в прошлом, нужны только новые
    // Если не срабатывает условие выше, то можно работать с переменныеми ниже
         // цена и   адрес
    //   // args[0], args[1] и можно работать с ними (выводить на экран)
    // })
  }

  updateStopped = async() => {
    const stopped = await this._auction.stopped()

    if(stopped){
      clearInterval(this.checkPriceInterval)
    }

    this.setState({
      stopped: stopped
    })

    return stopped
  }

  componentWillUnmount(){
    clearInterval(this.checkPriceInterval)
  }

  async updateBalance() {
    const newBalance = (await this._provider.getBalance(
      this.state.selectedAccount
    )).toString() // тк баланс возвращается в виде big number, а нужен string

    this.setState({
      balance: newBalance
    })
  }

  // всё ставим в значение null
  _resetState() {
    this.setState(this.initialState)
  }

  _checkNetwork() {
    if (window.ethereum.networkVersion === HARDHAT_NETWORK_ID) { return true }

    this.setState({
      networkError: 'Please connect to localhost:8545'
    })

    return false
  }

  _dismissNetworkError = () => {
    this.setState({
      networkError: null
    })
  }

  _dismissTransactionError = () => {
    this.setState({ 
      transactionError: null 
    })
  }

  // nextBlock = async() => {
  //   await this._auction.nextBlock()
  // }

  buy = async() => {
    try{
      const tx = await this._auction.buy({
        value: ethers.utils.parseEther(this.state.currentPrice)
      })

      this.setState({
        txBeingSent: tx.hash
      })

      await tx.wait()
    }catch (error){
      if(error.code === ERROR_CODE_TX_REJECTED_BY_USER) { return }

      console.error(error)

      this.setState({
        transactionError: error
      })
    }finally{
      this.setState({
        txBeingSent: null
      })
      await this.updateBalance()
      await this.updateStopped()
    }
  }

  _getRpcErrorMessage(error){
    if(error.data){
      return error.data.message
    }

    return error.message
  }

  render() {
    // если не выбран аккаунт
    if(!this.state.selectedAccount) {
      return <ConnectWallet
        connectWallet={this._connectWallet}
        networkError={this.state.networkError}
        dismiss={this._dismissNetworkError}
      />
    }

    if(this.state.stopped){
      return <p>Auction stopped.</p>
    }

    return(
      <>
        {this.state.txBeingSent && (
          <WaitingForTransactionMessage txHash={this.state.txBeingSent} />
        )}

        {this.state.transactionError && (
          <TransactionErrorMessage 
            message={this._getRpcErrorMessage(this.state.transactionError)}
            dismiss={this._dismissTransactionError}
          />
        )}

        {this.state.balance &&
          <p>Your balance: {ethers.utils.formatEther(this.state.balance)} ETH</p>}

        {this.state.currentPrice &&
          <div>
            <p>Current item price: {this.state.currentPrice} ETH</p>
            {/* <button onClick={this.nextBlock}>Next block</button> */}
            <button onClick={this.buy}>Buy!</button>
          </div>
        }
      </>
    )
  }
}

// npm run dev - для запуска next.js проекта