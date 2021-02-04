//var ProofOfSnake = artifacts.require("./ProofOfSnake.sol");
var SnakeArcade = arifacts.require("./SnakeArcade.sol");

module.exports = function (deployer) {
  //deployer.deploy(ProofOfSnake);
  deployer.deploy(SnakeArcade)
};
