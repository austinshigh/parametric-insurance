// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;


contract Insurance{
    /*
     * Each client describes a farmer that is insured by the agency.
     */
    struct CLIENT {
        uint256 farmer_id;        // unique id
        uint cost;                // monthly cost to farmer
        uint payout;              // payout made to farmer in event of drought
        uint rain;                // minimum amount of rain avoid payout (inches)
        uint dues_period;         // maximum amount of time allowed in between dues payments to agency (in seconds)
        uint payout_period;       // minimum amount of time allowed between payouts to farmer (in seconds)
        bool good_standing;       // true if farmer is up to date on payments
        uint last_paid_dues;      // date of last payment by farmer to agency
        uint last_payout;         // date of last drought payment
        address payable agency;   // account of the insurance company
        address payable account;  // account of the farmer
    }

    address public contract_owner;
    // tracks id number of newest farmer, ensures unique id per farmer
    uint256 public latest_id;

    mapping(uint256 => CLIENT) public client_registry;

    constructor() {
        latest_id = 0;
        contract_owner = msg.sender;
    }

    /*
     * register the farmer according to agreed upon terms of payment
     * @param cost: the amount of ether that the farmer pays per month
     * @param payout: the amount of ether that a farmer receives for each drought payout
     * @param rain: minimum amount of rain in inches required to avoid payout
     * @param farmer: the address of the farmer to be insured
     * @param dues_period: maximum amount of time allowed in between dues payments to agency
     * @param payout_period: minimum amount of time allowed between payouts to farmer
     * @return: normalized id for the next available farmer
     */
    function register_client(
        uint cost,
        uint payout,
        uint rain,
        uint dues_period,
        uint payout_period,
        address payable farmer
        ) 
    public returns (uint256) {
        require (msg.sender == contract_owner,
            "message sender must be contract owner.");
        
        require (cost < 10,
            "cost must be less than 10 ether.");
        
        require (payout < 10,
            "payout must be less than 10 ether.");
        
        client_registry[latest_id] = CLIENT(
            latest_id,                             // farmer id
            cost * 1000000000000000000,            // monthly cost to farmer (in wei)
            payout * 1000000000000000000,          // payout amount to pay to farmer in event of drought (in wei)
            rain,                                  // minimum amount of rain in inches required to avoid payout
            dues_period,                           // maximum time allowed between farmer's dues payments (seconds)
            payout_period,                         // minimum amount of time allowed between payouts to farmer (seconds)
            true,                                  // payment in good standing
            0,                                     // set last_paid_dues to 0, no dues paid yet
            0,                                     // set last_payout to 0, no payout yet
            msg.sender,                            // agency address
            farmer                                 // farmer address
        );

        // increment latest_id to ensure next farmer is given unique id
        latest_id += 1;

        return latest_id - 1;
    }

    /*
     * Make a payout to a farmer in the event of a drought, the agency must initiate this transaction
     * @param farmer_id: id of the farmer to pay
     * @return: status of payment
     */
     
    function pay_farmer(uint256 farmer_id) public payable returns(string memory client_status) {
        CLIENT storage client = client_registry[farmer_id];
        
        require(msg.value >= client.payout,
            "Must send enough wei to complete payout");

        require (msg.sender == client.agency, 
            "Payout not initiated by agency.");
           
        require(client.good_standing == true,
            "Too much time has elapsed since last payment, contact agency to rectify balance owed.");
        
        require ((block.timestamp - client.last_paid_dues < client.dues_period) || (client.last_paid_dues == 0),
            "Too much time has elapsed since last dues paid, contact agency to rectify balance owed.");

        require((block.timestamp - client.last_payout > client.payout_period) || (client.last_payout == 0),
            "Last payout was too recent, try again next pay-period.");
		
		require(contract_owner.balance >= client.payout,
			"Insufficient balance in insuror's account for withdrawal request");
           
		// send the amount to farmer who requested it
		client.account.transfer(client.payout);
		
		// set date of last drought to current blocktime
		client.last_payout = block.timestamp;
		
		return "farmer paid.";

    }
    
    /*
     * Make a payment to the agency, the farmer whose id is entered must initiate this transaction
     * @param farmer_id: id of the farmer to make dues payment
     * @return: status of payment
    */
    
    function pay_dues(uint256 farmer_id) public payable returns(string memory payment_status) {
        
        CLIENT storage client = client_registry[farmer_id];
        
        require(msg.value >= client.cost,
            "Must send enough wei to pay dues.");
        
        require (msg.sender == client.account, 
            "Payment not initiated by correct client's account.");
        
        require (client.good_standing == true,
            "Client is not in good standing, contact insurance agency for rectification.");
            
        require ((block.timestamp - client.last_paid_dues < client.dues_period) || (client.last_paid_dues == 0),
            "Too much time has elapsed since last dues paid, contact agency to rectify balance owed.");
		
		require(client.account.balance >= client.payout,
			"Insufficient balance in client's account for withdrawal request");
			
		// send the dues amount to the insurance agency
		client.agency.transfer(client.cost);
		
		// set date of last dues payment to current blocktime
		client.last_paid_dues = block.timestamp;
		
		return "dues paid.";
    }
    
    /*
     * Return the balance of the agency's account
     * @return: account balance
    */
    
    function agency_balance() view public returns(uint256) {
        return contract_owner.balance;
    }
    
    /*
     * Return the balance of the farmer
     * @param farmer_id: id of the farmer
     * @return: account balance
    */
    
    function farmer_balance(uint256 farmer_id) view public returns(uint256) {
        CLIENT storage client = client_registry[farmer_id];
        return client.account.balance;
    }
    
    /*
     * Bring a farmer back into good standing. Must be initiated by the contract owner
     * @param farmer_id: id of the farmer
     * @return: status of unpaid dues.
    */
    
    function rectify_unpaid_dues(uint256 farmer_id) public returns(string memory) {
        require (msg.sender == contract_owner);
        
        CLIENT storage client = client_registry[farmer_id];

        // set client good_standing to true to allow payouts
        client.good_standing = true;
        
        // set last paid dues as current time
        client.last_paid_dues = 0;

        return "unpaid dues rectified";
    }

}