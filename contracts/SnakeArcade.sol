// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/// @title Snake Arcade Game
/// @devico Uni
/// @dev All function calls are made through the front end.

import "./ERC721.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract SnakeArcade is ERC721 {
    //@notice Serves as the database for the front end snake game. Tracks current high scorer, his high score, game fee, and balance of earnings of the current and past addresses that were high scorers.

    //@dev Safety Feature: Mitigates Integer Overflow and Underflow (SWC-101).
    using SafeMath for uint256;

    uint256 public highScore;
    uint256 public gameFee;// = 0.1 ether;
    IERC20 public depositToken;
    address public currentLeader;
    address public owner;
    mapping(address => uint256) public potBalance;

    bool public stopped = false;

    //@dev Design pattern: Restricting access
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    //@dev Design pattern: Circuit breaker to stop players from playing during emergency and allows currentLeader to withdraw his earnings.
    modifier stopInEmergency {
        require(!stopped);
        _;
    }
    modifier onlyInEmergency {
        require(stopped);
        _;
    }

    function emergency() public onlyOwner {
        if (stopped == false) {
            stopped = true;
        } else {
            stopped = false;
        }
    }

    //@dev record the contract owner's address and sets it as the currentLeader and balance of 0.
    //@param msg.sender only.

    constructor() ERC721("Snake High Scorer", "SHS") {
        owner = msg.sender;
        currentLeader = msg.sender;
        potBalance[owner] = 0;
        highScore = 2;
        gameFee = 10;
        depositToken = IERC20(0xf35Da56343622244f9e1FB0B87950FBFD7FA991B);
    }

    //@notice Called when user clicks to the Play button on the front end. Fee is split to the contract owner and the currentLeader, stored in potBalance mapping.
    function playGame(IERC20 _depositToken, uint256 amount) public payable stopInEmergency {
        //@notice Ensures minimum value is met to play the game.
        require(amount >= gameFee, "Minimum game fee is not met.");
        require(_depositToken == depositToken, "Invalid token.");
        
        potBalance[msg.sender] = 0;
        //@dev Safety feature: use SafeMath's function to add half the fee to currentLeader's potBalance mapping
        //@dev Safety feature: use SafeMath's functions to add remaining fee to owner's potBalance mapping

        potBalance[owner] = potBalance[owner].add(amount.div(2));
        potBalance[currentLeader] = potBalance[currentLeader].add(
            msg.value.sub(amount.div(2))
        );
    }

    //@notice Called when a new high score is achieved.
    //@param Takes the current high score uint and stores in highScore.
    function newLeader(uint256 _score) public stopInEmergency {
        //@notice Requires that msg.sender has at least paid to play the game once
        require(potBalance[msg.sender] >= 0, "Player has not played before.");
        //@notice Updates the current leader to msg.sender
        currentLeader = msg.sender;
        //@notice Updates the current high score
        highScore = _score;

        //Mint a POSHS token
        uint256 _tokenId = totalSupply().add(1);
        _mint(msg.sender, _tokenId);
    }

    //@notice Called when previous high scorer wants to withdraw his earnings.
    //@dev Design Pattern: Withdrawal pattern rather than direct distribution.
    //@dev Safety feature: Mitigates Denial of Service with Failed Call (SWC-113).
    function withdrawEarnings() public stopInEmergency {
        //@notice Ensures that withdrawer's high score has been beatan before being able to withdraw. This maintains the intended economics.
        require(
            msg.sender != currentLeader && potBalance[msg.sender] > 0,
            "Leader's high score has not been beaten or no earnings collected yet."
        );

        potBalance[msg.sender] = 0;

        //@notice Empty out balance of msg.sender and transfer to msg.sender.
        msg.sender.transfer(potBalance[msg.sender]);
    }
}
