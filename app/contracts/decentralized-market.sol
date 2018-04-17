pragma solidity ^0.4.17;


contract Market {
	

	struct Category {

		string description;
		bool status; // 0 = Inactive; 1 = Active;

	}

	struct Product {

		bytes32 name;
		uint stock;
		uint sold;
		uint price;
		mapping(address => bool) likes;
		uint likesCounter;
		mapping(address => bool) dislikes;
		uint dislikesCounter;
		bytes32 category;
		bool status; // 0 = Inactive; 1 = Active;

	}

	struct Order {

		bytes32 hashOrder;
		uint idProduct;
		uint quantity;
		uint total;
		uint status; 
		/*
		Status:
			0 = Order doesn't exists.
			1 = Pending to be approved;
			2 = Available in physical market.
		*/
	}

	struct OrderInternal {

		address buyer;
		uint idOrder;

	}

	address public owner;
	uint public productsCounter = 0;
	uint nonce = 1;
	uint mixerA = 1337;
	uint mixerB = 3693;
	mapping(bytes32 => Category) public categories;
	mapping(uint => Product) public products; 
	mapping(address => Order[]) private ordersCompleted;
	mapping(address => uint) private counterOrdersCompleted;
	mapping(bytes32 => OrderInternal) private hashOrder2idOrder;

	modifier onlyOwner {

		require(msg.sender == owner);
		_;

	}

	function Market () public {

		owner = 0xBB2048F1be4C6E794b20502437D09552b4BC07f0;

	}

	function numberOrdersCompleted () public constant returns (uint) {

		return counterOrdersCompleted[msg.sender];

	}

	function getMyOrdersCompleted (uint _numberOrder) public constant 
			returns (bytes32, uint, uint, uint, uint) {

		bytes32 _hashOrder = ordersCompleted[msg.sender][_numberOrder].hashOrder;
		uint _idProduct = ordersCompleted[msg.sender][_numberOrder].idProduct;
		uint _quantity = ordersCompleted[msg.sender][_numberOrder].quantity;
		uint _total = ordersCompleted[msg.sender][_numberOrder].total;
		uint _status = ordersCompleted[msg.sender][_numberOrder].status;
		
		return (_hashOrder, _idProduct, _quantity, _total, _status);
	
	}

	function addCategory (bytes32 _categoryName, string _description) onlyOwner public {

		categories[_categoryName].description = _description;
		categories[_categoryName].status = true;

	}

	function addProduct (bytes32 _productName, uint _stock, uint _price) 
			onlyOwner public {

		products[productsCounter].name = _productName;
		products[productsCounter].stock = _stock;
		products[productsCounter].price = _price;
		products[productsCounter].status = true;
		productsCounter++;

	}

	function buyProduct (uint _idProduct, uint _quantity) public payable {

		require(products[_idProduct].status && 
				msg.value == (_quantity * products[_idProduct].price) &&
				products[_idProduct].stock >= _quantity);

		Order memory _tmp;
		bytes32 hashOrder = keccak256(nonce + (mixerA * nonce) + (mixerB * now));
		products[_idProduct].stock = products[_idProduct].stock - _quantity;
		_tmp.hashOrder = hashOrder;
		_tmp.idProduct = _idProduct;
		_tmp.quantity = _quantity;
		_tmp.total = msg.value;
		hashOrder2idOrder[hashOrder].idOrder = counterOrdersCompleted[msg.sender];
		hashOrder2idOrder[hashOrder].buyer = msg.sender;
		ordersCompleted[msg.sender].push(_tmp);
		counterOrdersCompleted[msg.sender]++;

	}

	function changeStatusCategory (bytes32 _categoryName) onlyOwner public {

		categories[_categoryName].status = !categories[_categoryName].status;

	}

	function changeStatusProduct (uint _idProduct) onlyOwner public {

		products[_idProduct].status = !products[_idProduct].status;

	}

	function deleteCategory (bytes32 _categoryName) onlyOwner public {

		delete categories[_categoryName];

	}

	function deleteProduct (uint _idProduct) onlyOwner public {

		delete products[_idProduct];

	}

	function withdraw (uint _amount) onlyOwner public {

		require(this.balance > _amount);
		owner.transfer(_amount);

	}

	function giveLike (uint _idProduct) public {

		require(products[_idProduct].status && !products[_idProduct].likes[msg.sender]);
		if (products[_idProduct].dislikes[msg.sender]) {
		
			delete products[_idProduct].dislikes[msg.sender];
			products[_idProduct].dislikesCounter--;

		}

		products[_idProduct].likes[msg.sender] = true;
		products[_idProduct].likesCounter++;
		
	}

	function giveDislike (uint _idProduct) public {

		require(products[_idProduct].status && !products[_idProduct].dislikes[msg.sender]);
		if (products[_idProduct].likes[msg.sender]) {
		
			delete products[_idProduct].likes[msg.sender];
			products[_idProduct].likesCounter--;

		}

		products[_idProduct].dislikes[msg.sender] = true;
		products[_idProduct].dislikesCounter++;
		
	}

	function changeStatusOrderCompleted (bytes32 _hashOrder, uint _status) onlyOwner public {
		/*
		_status:
			0 = Order doesn't exists.
			1 = Pending to be approved;
			2 = Available in physical market.
		*/
		uint _numberOrder = hashOrder2idOrder[_hashOrder].idOrder;
		address _buyer = hashOrder2idOrder[_hashOrder].buyer;
		ordersCompleted[_buyer][_numberOrder].status = _status;

	}

}