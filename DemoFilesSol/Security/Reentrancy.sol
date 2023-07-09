// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Слово «reentrancy» означает «повторный вход». Всякий раз, когда смарт-контракт делает внешний вызов другому смарт-контракту, может быть осуществлен повторный выход в исходную функцию. Кроме того, когда смарт-контракт делает внешний вызов, выполнение EVM передается от смарт-контракта, выполняющего вызов, к тому, который вызывается.
contract ReentrancyAuction{
    mapping(address => uint) public bidders;
    bool locked; // изначально тут false

    function bid() external payable{
        bidders[msg.sender] += msg.value; 
    }

    // Только имя модификатора лучше с маленькой буквы начинать
    modifier NoReentrancy(){
        require(!locked, "no reentrancy!"); // при первом заходе locked = false => будет он true и мы пройдем вниз
        locked = true;
        _; // сама наша функция, то есть как наша функция закончится, то мы изменим locked на false. Модификатор это часть кода которая вставляется в функция для проверки чего-либо. Модификаторы функций используются для изменения поведения функции. Например, чтобы добавить необходимое условие к функции.
        locked = false;
    }

    // модификатор нас спасает от рекурсии, то есть при первом заходе мы делаем переменную locked в true и нашем повторном запросе, когда к нам приходят деньги мы снова обращаемся к refund, то мы снова заходим в модификатор и ловим ошибку на require, где у нас locked в значении true и мы выходим из данного повторного запроса, тем самым наша изначальная функция подходит к концу и locked = false; и атака просто не пройдёт
    // подход pull
    function refund() external NoReentrancy{
        uint refundAmount = bidders[msg.sender];

        // Вариант - 1
        if (refundAmount > 0){ // так не украдут деньги
            bidders[msg.sender] = 0;

            (bool success, ) = msg.sender.call{
                value: refundAmount
            }(""); 

            require(success, "failed!");
        }

        // Вариант - 0
        // if (refundAmount > 0){ так украдут деньги
        //     (bool success, ) = msg.sender.call{
        //         value: refundAmount
        //     }(""); // делаем низкоуровневый запрос чтобы вернуть деньги и передаем пустую строку, чтоб просто передать деньги на кошелёк msg.sender

        //     require(success, "failed!");

        //     bidders[msg.sender] = 0;
        // }
    }

    function currentBalance() external view returns(uint) {
        return address(this).balance;
    }
}

contract ReentrancyAttack{
    uint constant BID_AMOUNT = 1 ether;
    ReentrancyAuction auction;

    constructor(address _auction){
        auction = ReentrancyAuction(_auction);
    }

    function proxyBid() external payable{
        require(msg.value == BID_AMOUNT, "Incorrect");
        auction.bid{value: msg.value}();
    }
    
    function attack() external {
        auction.refund();
    }

    // Будет работать с "Вариантом-0"
    receive() external payable {
        if (auction.currentBalance() >= BID_AMOUNT) {
            auction.refund(); 
        }
        // атакуем аукцион таким образом, что сначала отработает функция attack() затем мы перейдем в функцию refund(нашего смартконтракта выше) и мы проведем проверку, что да мол у нас была ставка и мы хотим вернуть что-то. Затем мы заходим на call и возвращаемся на наш Хакерский смартконтракт и входим в функцию receive(), а в ней у нас точно такой же запрос к refund(), тем самым мы возвращаемся и тк мы нигде не перезаписывали нашу переменную refundAmount, то получается мы заходим в бесконечный цикл получения денег с смартконтракта ReetrancyAuction и таким образом мы можем забрать все деньги с него. 
    }

    function currentBalance() external view returns(uint) {
        return address(this).balance;
    }
}