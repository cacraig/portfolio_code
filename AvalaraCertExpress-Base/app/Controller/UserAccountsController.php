<?php
/*---------------------------------------------------
 * UserAccountsController
 * --------------------------------------------------
 * Handles User Account information requests, and CRUD. 
 * 
 * 
 * TODO: Test, and debug.
 *       Assure Headers are being set properly.
 *       Finish HTTP error setting.
 *       Add More meaningful messages upon database failures. (Codes: 400, 409)
 *       Edit default Collections return (No specified params)
 * Created By: Colin Craig
 * Last Updated: 3/18/2013
 *
 * 
 */

// Constants to be moved to Config file.
define('PUBLIC_BILLING_TIER_ID','2');
define('PUBLIC_USER_ROLE_ID','3');
define('PUBLIC_COMPANY_DB_ID','2');
define('MAX_PAGES','2');
define('DEFAULT_PAGE','1');
define('DEFAULT_LIMIT','1');

  
class UserAccountsController extends AppController {
	
	public $uses = array();
	public $components = array('RequestHandler');
	public $name = 'UserAccounts';
	
	/*
	 * Before Filter...
	 * 
	 */
    public function beforeFilter() {
    	App::import('Model','UserAccount');
        $this->UserAccount = new UserAccount();
        parent::beforeFilter();
    }

	/*
	 * -----------------------------------------------------
	 * index()
	 * -----------------------------------------------------
	 * HTTP Request - GET
	 * 
	 * Gets all user account data.
	 * 
	 * HTTP GET Request Example: 
	 *     .../user_accounts.json
	 *     
	 *     => Maps To: UserAccountsController::index()
	 *     => .json extension maps to app/View/UserAccounts/json/index.ctp
	 * 
	 */
    function index(){

        // Get query params to edit account.
        $query_params = $this->request->query;
        // Check for page params
        if(!empty($query_params['page'])){
            $page = $query_params['page'];
            unset($query_params['page']);
        }else{
            $page = DEFAULT_PAGE;
            unset($query_params['page']);
        }
            
        if(!empty($query_params['limit'])){
            $limit = $query_params['limit'];
            unset($query_params['limit']);
        }else{
            $limit = DEFAULT_LIMIT;
            unset($query_params['limit']);
        }

        $data = (!empty($query_params)) ? $this->UserAccount->findCollection($query_params,$page,$limit) 
                                            : $this->UserAccount->findDefaultCollection($page,$limit);
        $this->set('results',json_encode($data));
        return;
	}
	
	/*
     * -----------------------------------------------------
     * view($id)
     * -----------------------------------------------------
     * HTTP Request - GET
     * 
     * Gets all user account data.
     * 
     * HTTP GET Request Example: 
     *     .../user_accounts/$id.json
     *     
     *     => Maps To: UserAccountsController::index()
     *     => .json extension maps to app/View/UserAccounts/json/view.ctp
     * 
     * ================================
     * @param int $id - User Account id
     * ================================
     */
	function view($id){

		$user_account = $this->UserAccount->findById($id);
		$this->set('results',json_encode($user_account));
	}
	
    /*
     * -----------------------------------------------------
     * edit($id)
     * -----------------------------------------------------
     * HTTP Request - PUT/POST
     * 
     * Edits Current User Account Data.
     * 
     * HTTP PUT/POST Request Example: 
     *     .../user_accounts/$id.json
     *     
     *     => Maps To: UserAccountsController::edit($id)
     *     => .json extension maps to app/View/UserAccounts/json/edit.ctp
     *     
     * ================================
     * @param int $id - User Account id to edit.
     * ================================
     * 
     * TODO: Filter for escape characters, and sql/script injection.
     * 
     */
    function edit($id){
    	
    	// Get query params to edit account.
        if(!empty($this->request->data)){
            $query_params = $this->request->data;
        }else{
            $code = $this->setErrorCode(HTTP_BAD_REQUEST);
            $this->set('results',json_encode($code));
            return;
        }
        
        // Set Model id.
    	$this->UserAccount->id = $id;
    	
    	// Loop through and process query parameters.
    	foreach ($query_params as $key => $val){
    		
    		switch($key) {
    			
    			case 'name':
    				// Filter input & save...else throw error
    				$this->UserAccount->saveField('name',$val);
    				break;
    			case 'phone':
    				// Filter input & save...else throw error
    				$this->UserAccount->saveField('phone',$val);		
    				break;
    			case 'billing_tier_id':
    			    // Permissions check for sysadmin or user going up in billing tier.
                    // Check for appropriate buyer count, seller count, cert count if going down.
                    if(true){
                    	// Permission -- SUCCESS
                    	// Try to save field, throw error if billing_tier_id does not exist,
                    	// or cannot be changed.
                    	try{
                    		$this->UserAccount->saveField('billing_tier_id',$val);
                    	} catch (Exception $e){
                    		
                    		$code = $this->setErrorCode(HTTP_BAD_REQUEST);
                            $this->set('results',json_encode($code));
                    		return;
                        }
                    }else{
                    	// Invalid Permissions.
                    	// Throw (403) Forbidden Error.
                    	$code = $this->setErrorCode(HTTP_FORBIDDEN);
                    	$this->set('results',json_encode($code));
                    	return;
                    }
                    break;
    			case 'status':
    				// Permissions check for sysadmin.
                    if(true){
                        // Permission -- SUCCESS
                        // Throw (400) Bad Request error if save fails.
                        try{
                            $this->UserAccount->saveField('status',$val);
                        } catch (Exception $e){
                        	$code = $this->setErrorCode(HTTP_BAD_REQUEST);
                            $this->set('results',json_encode($code));
                            return;
                        }
                    }else{
                    	// Invalid Permissions.
                        // Throw (403) Forbidden Error.
                        $code = $this->setErrorCode(HTTP_FORBIDDEN);
                        $this->set('results',json_encode($code));
                        return;
                    }
                    break;
    		}

    	}
    	
    	// Build Single-Resource output.
    	// Set Single-Resource URL.
    	$user = $this->UserAccount->findById($id);
    	$user['UserAccount']['url'] = 'https://certexpressapi.avalara.com/user_accounts/'.$id.'.json';
    	
    	// This is done for easier compaction of json data.
    	$userAccount = $user['UserAccount'];

    	// Set Success Error code, and output results.
        $code = $this->setErrorCode(HTTP_OK);
        $results = compact('userAccount','code');
        $this->set('results',json_encode($results));
    }
    
    /*
     * -----------------------------------------------------
     * add()
     * -----------------------------------------------------
     * HTTP Request - POST
     * 
     * Add a user given information in request
     * 
     * HTTP POST Request Example: 
     *     .../user_accounts.json
     *     
     *     => Maps To: UserAccountsController::add()
     *     => .json extension maps to app/View/UserAccounts/json/add.ctp
     * 
     */
    function add(){
    	
    	// Get query params to obtain information for creating an account.
    	if(!empty($this->request->data)){
            $query_params = $this->request->data;
    	}else{
    		$code = $this->setErrorCode(HTTP_BAD_REQUEST);
            $this->set('code',json_encode($code));
            return;
    	}
    	
    	//Create Row instance.
    	$this->UserAccount->create();
    	
    	// Check if billing_tire_id or user_role_id defined
    	// if not, set to DEFAULT Public id's.
        $query_params['billing_tier_id'] = (!empty($query_params['billing_tier_id'])) ? 
                                                     $query_params['billing_tier_id'] : PUBLIC_BILLING_TIER_ID;
                                                     
        $query_params['user_role_id'] = (!empty($query_params['user_role_id'])) ? 
                                                     $query_params['user_role_id'] : PUBLIC_USER_ROLE_ID;
                                                     
        $query_params['company_database_id'] = PUBLIC_COMPANY_DB_ID;
    	
    	foreach ($query_params as $key => $val){
    		$this->UserAccount->set($key,$val);
    	}
    	
    	try{
    		
    	    $this->UserAccount->save();
    	    $id = $this->UserAccount->getLastInsertID();
            $q_result = $this->UserAccount->query("SELECT * FROM user_accounts WHERE id=".$id);
    	    $userAccount = $q_result[0][0];
    	} catch (Exception $e){
    		//Throw (400) Bad request error.
    	    $code = $this->setErrorCode(HTTP_CONFLICT);
            $this->set('results',json_encode($code));
            return;
    	}
    	
    	// Build Single-Resource output.
        // Set Single-Resource URL.
        $userAccount['url'] = 'https://certexpressapi.avalara.com'.'/'.$this->MarketingSeller->model."/".$userAccount['id'].'.json';

        // Set Success Error code, and output results.
        $code = $this->setErrorCode(HTTP_OK);
        $results = compact('userAccount','code');
        $this->set('results',json_encode($results));
    }
    
    /*
     * -----------------------------------------------------
     * delete()
     * -----------------------------------------------------
     * HTTP Request - DELETE
     * 
     * Deletes Current User Account Data.
     * 
     * HTTP DELETE Request Example: 
     *     .../user_accounts/123.json
     *     
     *     => Maps To: UserAccountsController::delete($id)
     *     => .json extension maps to app/View/UserAccounts/json/delete.ctp
     *     
     * ================================
     * @param int $id - User Account id to edit.
     * ================================   
     */
    function delete($id){
    	
    	// Delete a resource.
    	// Success -> set $results.
    	// Fail -> Set $code with error code. 
        try{
        	$this->UserAccount->delete($id);
        	$code = $this->setErrorCode(HTTP_OK);
            $this->set('results',json_encode($code));
        } catch (Exception $e){
        	$code = $this->setErrorCode(HTTP_BAD_REQUEST);
            $this->set('code',json_encode($code));
        }
    }
}

?>