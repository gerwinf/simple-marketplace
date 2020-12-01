pragma solidity >=0.4.21 <0.7.0;

import "./SafeMath.sol";

contract Marketplace {

  address payable owner;
  uint productCount;
  mapping (uint => Product) public products;
  bool isActive = true;

  struct Product {
    uint id;
    string name;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  enum State {
    ForSale,
    Sold
  }

  event LogAddressSeller(address);
  event LogAddressBuyer(address);
  event LogForSale(uint id);
  event LogSold(uint id);

  modifier onlyOwner() {require(owner == msg.sender); _;}
  modifier contractIsActive() { require(isActive == true); _;}
  modifier paidEnough(uint _price) { require(msg.value >= _price); _;}
  modifier checkValue(uint _id) {
    _;
    uint _price = products[_id].price;
    uint amountToRefund = msg.value - _price;
    products[_id].buyer.transfer(amountToRefund);
  }
  modifier forSale(uint _id) { require(products[_id].state == State.ForSale && products[_id].buyer == address(0)); _;}
  modifier sold(uint _id) { require(products[_id].state == State.Sold); _;}

  constructor() public {
    owner = msg.sender;
    productCount = 0;
  }

  function toggleCircuitBreaker() external onlyOwner() {
      isActive = !isActive;
  }

  function kill() external onlyOwner() {
      selfdestruct(owner);
  }

  function getCount() public view returns (uint id) {
    return productCount;
  }

  function addProduct(string memory _name, uint _price) contractIsActive() public returns(bool) {
    emit LogForSale(productCount);
    products[productCount] = Product({name: _name, id: productCount, price: _price, state: State.ForSale, seller: msg.sender, buyer: address(0)});
    productCount += 1;
    return true;
  }

  using SafeMath for uint;

  function buyProduct(uint id)
    public payable forSale(id) paidEnough(products[id].price) checkValue(id) contractIsActive()
  {
    products[id].buyer = msg.sender;
    uint commission = SafeMath.div(products[id].price, 20);
    uint shareSeller = SafeMath.sub(products[id].price, commission);
    products[id].seller.transfer(shareSeller);
    products[id].state = State.Sold;
    owner.transfer(commission);

    emit LogSold(id);
    emit LogAddressBuyer(products[id].buyer);
    emit LogAddressSeller(products[id].seller);
  }

  function fetchProduct(uint _id) public view returns (string memory name, uint id, uint price, uint state, address seller, address buyer) {
    name = products[_id].name;
    id = products[_id].id;
    price = products[_id].price;
    state = uint(products[_id].state);
    seller = products[_id].seller;
    buyer = products[_id].buyer;
    return (name, id, price, state, seller, buyer);
  }
}
