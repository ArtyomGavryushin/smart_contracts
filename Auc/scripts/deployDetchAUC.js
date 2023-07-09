// для работы с сетью hardhat
const hre = require('hardhat');  
// данный плагин приносит в hardhat библиотеку Ethereum ethers.js, которая позволяет взаимодействовать с блокчейном Ethereum
const ethers = hre.ethers;
// данный модуль fs позволяет взаимодействовать с файловой системой 
const fs = require('fs');
// модуль node.js Path является встроенным и представляет набор функций для работы с путями в файловой системе
const path = require('path');

async function main() {
  // проверка на то что сеть на которую мы разворачиваем не является сетью hardhat
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    ); // советуем использовать localhost
  }

  // кто разворачивает данный смарт контракт
  const [deployer] = await ethers.getSigners()

  console.log("Deploying with", await deployer.getAddress())

  const DutchAuction = await ethers.getContractFactory("DutchAuction", deployer)
  const auction = await DutchAuction.deploy(
    ethers.utils.parseEther('2.0'),
    1,
    "Motorbike"
  )
  await auction.deployed()

  saveFrontendFiles({
    DutchAuction: auction
  })
}

// принимаем контракты которые мы хотим скопировать для frontend'a
function saveFrontendFiles(contracts) {
  // директория, где лежат контракты
  const contractsDir = path.join(__dirname, '/..', 'frontend/contracts')

  // если нету директории, то мы её создаём
  if(!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir)
  }

  Object.entries(contracts).forEach((contract_item) => {
    const [name, contract] = contract_item

    // если контракт есть, то мы создаем файлы 
    if(contract) {
      fs.writeFileSync(
        // файл с названием и адресом развёрнутого контракта
        path.join(contractsDir, '/', name + '-contract-address.json'),
        // записываем содержимое в данный файл
        JSON.stringify({[name]: contract.address}, undefined, 2)
      )
    }

    // файл, где лежит интерфейс
    const ContractArtifact = hre.artifacts.readArtifactSync(name)

    // содержимое артифакта (интерфейс)
    fs.writeFileSync(
      path.join(contractsDir, '/', name + ".json"),
      JSON.stringify(ContractArtifact, null, 2)
    )
  })
}

// запуск всех функций
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })

// npx hardhat clean
// npx hardhat node
// затем чтобы развернуть смартконтракт в сети hardhat
// npx hardhat run scripts\deployDetchAUC.js --network localhost