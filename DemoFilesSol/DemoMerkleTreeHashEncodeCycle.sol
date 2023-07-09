// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Merkle Tree, Hash, Encode, Cycle

contract Tree {
    //      ROOT 0xa0da473a78c18b28d88660e9e845ae6ff6b0cc3e7e6901a4fc8cad162a6aaba8
    //       6
    //  H1-2    H3-4
//indx   4        5
    // H1  H2  H3  H4
//index 0  1   2   3
    // TX1 TX2 TX3 TX4 Листья дерева
    
    // для проверки TX3: John -> Mary
    // indexes hashes
    // проверка для индекса 2.
    // ROOT 0xa0da473a78c18b28d88660e9e845ae6ff6b0cc3e7e6901a4fc8cad162a6aaba8 , а то что ниже записать ввиде массива строк
    // 3 0xdca11aec2d04146b1bbc933b1447aee4927d081c9274fcc6d02809b4ee2e56d8
    // 4 0x58e9a664a4c1e26694e09437cad198aebc6cd3c881ed49daea6e83e79b77fead

    bytes32[] public hashes; 
    string[4] transactions = [
        "TX1: Sherlock -> John",
        "TX2: John -> Sherlock",
        "TX3: John -> Mary",
        "TX3: Mary -> Sherlock"
    ]; // 2^2

    constructor(){
        for(uint i = 0; i < transactions.length; i++){
            hashes.push(makeHash(transactions[i])); // реализация Hash1 H2 H3 H4
        }

        uint count = transactions.length;
        uint offset = 0;

        while(count > 0){
            for(uint i = 0; i < count - 1; i +=2 ){
                hashes.push(keccak256(
                    // делаем вручную, тк наша функция makeHash принимает только лишь 1 строку, а нам нужно по 2 элемента объединять
                    abi.encodePacked(
                        hashes[offset + i], hashes[offset + i + 1] // offset + i + 1 соседний элемент для хэширования
                    )
                ));
            }
            offset += count; 
            count = count / 2;
        }
    }

    // Например, если мы хотим проверить H3, то нам нужны только 2 элемента: H4 и H1-2, их мы записываем в массив proof; [H4, H1-2]

    function verify(string memory transaction, uint index, bytes32 root, bytes32[] memory proof) public pure returns(bool){
        bytes32 hash = makeHash(transaction);

        for(uint i = 0; i < proof.length; i++){
            bytes32 element = proof[i];

            if(index % 2 == 0){
                hash = keccak256(abi.encodePacked(hash, element));
            } else {
                hash = keccak256(abi.encodePacked(element, hash));
            }

            index = index / 2;
        } 

        return hash == root;
    }

    // bytes memory (массив) потому что
    function encode(string memory input) public pure returns(bytes memory){ // возвращаться будет произвольная длина тк всегда будет формироваться разная длина строки взависимости от input переменной
        return abi.encodePacked(input); 
    }

    function makeHash(string memory input) public pure returns(bytes32){
        return keccak256(
            encode(input)
            // abi.encodePacked() // правильная кодировка
        ); // возвращает хэш длинной 32 (byte) * 8 бит = 256 бит

    }
}