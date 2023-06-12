// An erc-20 token that implements the encumber interface by blocking transfers.

pragma solidity ^0.8.0;
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract EncumberableErc20 is ERC20 {
    // Owner -> Taker -> Amount that can be taken
    mapping (address => mapping (address => uint)) public encumbrances;

    // The encumbered balance of the token owner. encumberedBalance must not exceed balanceOf for a user
    // Note this means rebasing tokens pose a risk of diminishing and violating this prototocol
    mapping (address => uint) public encumberedBalance;
    
    address public minter;

    event Encumber(address indexed owner, address indexed taker, uint encumberedAmount);
    event Release(address indexed owner, address indexed taker, uint releasedAmount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        minter = msg.sender;
    }

    function mint(address recipient, uint amount) public virtual returns (bool) {
        require(msg.sender == minter, "only minter");
        _mint(recipient, amount);
        return true;
    }

    function encumber(address taker, uint amount) public virtual returns (bool) {
        _encumber(msg.sender, taker, amount);
        return true;
    }

    function encumberFrom(address owner, address taker, uint amount) public virtual returns (bool) {
        require(allowance(owner, msg.sender) >= amount);
       _encumber(owner, taker, amount);
       return true;
    }

    function release(address owner, uint amount) public virtual returns (bool) {
        _release(owner, msg.sender, amount);
        return true;
    }

    // If bringing balance and encumbrances closer to equal, must check
    function freeBalanceOf(address a) public view returns (uint) {
        return (balanceOf(a) - encumberedBalance[a]);
    }

    function _encumber(address owner, address taker, uint amount) private {
        require(freeBalanceOf(owner) >= amount, "insufficient balance");
        encumbrances[owner][taker] += amount;
        uint ownerTotal = encumberedBalance[owner] += amount;
        emit Encumber(owner, taker, amount);
    }

    function _release(address owner, address taker, uint amount) private {
        if (encumbrances[owner][taker] < amount) {
          amount = encumbrances[owner][taker];
        }
        encumbrances[owner][taker] -= amount;
        uint ownerTotal = encumberedBalance[owner] -= amount;
        emit Release(owner, taker, amount);
    }

    function transfer(address dst, uint amount) public override returns (bool) {
        // check but dont spend encumbrance
        require(freeBalanceOf(msg.sender) >= amount, "insufficient balance");
        _transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint amount) public override returns (bool) {
        uint encumberedToTaker = encumbrances[src][msg.sender];
        bool exceedsEncumbrance = amount > encumberedToTaker;
        if (exceedsEncumbrance)  {
            uint excessAmount = amount - encumberedToTaker;
            // Exceeds Encumbrance , so spend all of it
            _spendEncumbrance(src, msg.sender, encumberedToTaker);

            // Having spent all the tokens encumbered to the mover,
            // We are now moving only "free" tokens and must check
            // to not unfairly move tokens encumbered to others

           require(freeBalanceOf(src) >= excessAmount, "insufficient balance");

            _spendAllowance(src, dst, excessAmount);
        } else {
            _spendEncumbrance(src, msg.sender, amount);
        }

        _transfer(src, dst, amount);
        return true;
    }

    function _spendEncumbrance(address owner, address taker, uint256 amount) internal virtual {
        uint256 currentEncumbrance = encumbrances[owner][taker];
        require(currentEncumbrance >= amount, "insufficient encumbrance");
        uint newEncumbrance = currentEncumbrance - amount;
        encumbrances[owner][taker] = newEncumbrance;
        encumberedBalance[owner] -= amount;
    }
}

