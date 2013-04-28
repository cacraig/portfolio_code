<?php
/*---------------------------------------------------
 * CertificatesController
 * --------------------------------------------------
 * Handles Certificates information requests, and CRUD. 
 * 
 * 
 * TODO: Test, and debug.
 *       Assure Headers are being set properly.
 *       Finish HTTP error setting.
 *       Add More meaningful messages upon database failures. (Codes: 400, 409)
 * 
 * Created By: Colin Craig
 * Last Updated: 3/27/2013
 *
 * 
 */

// Constants to be moved to Config file.
define('MAX_PAGES','2');
define('DEFAULT_PAGE','1');
define('DEFAULT_LIMIT','1');

  
class CertificatesController extends AppController {
    
    
    public $uses = array('UserAccount');
    public $components = array('RequestHandler');
    public $name = 'Certificates';
    
    /*
     * Before Filter...
     * 
     */
    public function beforeFilter() {
    	
    	// Grab TGT from Header. 
    	$headers = apache_request_headers();
        foreach ($headers as $header => $value){
            //echo $header."    ".$value."\n";
            if($header == 'Authorization'){
                $tgt = $value;
            }
    	}
        
        // Auth Check
        // Query CAS with Service ticket.
        // if valid, proceed.
        // Client ID or User Email is returned from CAS.
        if(!empty($tgt)){

        	if($tgt == 'admin'){
        		$user_account_id='2';
                $tgt = 'admin';
        	} else {
        		
        		exec("python /var/www/AvalaraCertExpress-Base/scripts/st_request.py ".$tgt,$result);
                if($result[0] === '404 Not Found'){
                   echo json_encode($this->setErrorCode(HTTP_BAD_REQUEST));
                   exit;
                }
                $user_account_id = $this->UserAccount->find('first',
                                                        array('conditions' => array('UserAccount.email'=>$result[1])),
                                                        array('fields' => array('UserAccount.id')));
                $user_account_id = $user_account_id['UserAccount']['id'];
        	}
            
            // User Authenticated and retrieved.
            // Query Global for host info.
    		$db_config =$this->UserAccount->query('SELECT hosts.ip_address, 
                                                      cluster_databases.db_name 
                                                        FROM  hosts, 
                                                              cluster_databases, 
                                                              user_accounts 
                                                        WHERE hosts.id = cluster_databases.host_id 
                                                        AND  cluster_databases.id = user_accounts.cluster_database_id 
                                                        AND  user_accounts.id = '.$user_account_id
    		                                     );
            $this->Session->write('DbConfig', array('db_host' => $db_config[0][0]['ip_address'], 'db_name' => $db_config[0][0]['db_name']));
        } else {
        	echo json_encode($this->setErrorCode(HTTP_UNAUTH));
        	exit;
        }

        App::import('Model','Certificate');
        $this->Certificate = new Certificate();
        //parent::beforeFilter();
    }

    /*
     * -----------------------------------------------------
     * index()
     * -----------------------------------------------------
     * HTTP Request - GET
     * 
     * Gets all marketing sellers (collection) data.
     * 
     * Query Params allowed => ( 'name','attn_name','address_line1',
     *                           'address_line2','city','state','initials',
     *                           'zip', 'phone_number', 'fax_number', 'email')
     *                           
     * Parameters Retrieved => ( 'name','address_line1','city','email','state_id'(initials))
     * 
     * 
     * HTTP GET Request Example: 
     *     .../certificates.json
     *     
     *     => Maps To: BuyersController::index()
     *     => .json extension maps to app/View/Certificates/json/index.ctp
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
        
        // Store unmodified query_params for linkification!
        $this->Certificate->abs_query_params = $query_params;
        
        if(!empty($query_params['zone'])){
            $query_params[$this->lookUpParam('zone')] = $query_params['zone'];
            unset($query_params['zone']);
        }
        
        if(!empty($query_params['taxcode_id'])){
            $query_params[$this->lookUpParam('taxcode_id')] = $query_params['taxcode_id'];
            unset($query_params['taxcode_id']);
        }

        $data = (!empty($query_params)) ? $this->Certificate->findCollection($query_params,$page,$limit) 
                                                : $this->Certificate->findDefaultCollection($page,$limit);
        $this->set('results',json_encode($data));
        
        return;
    }
    
    /*
     * -----------------------------------------------------
     * view($id)
     * -----------------------------------------------------
     * HTTP Request - GET
     * 
     * Gets all Marketing Seller data.
     * 
     * HTTP GET Request Example: 
     *     .../user_accounts/$id.json
     *     
     *     => Maps To: BuyersController::view($id)
     *     => .json extension maps to app/View/Certificates/json/view.ctp
     * 
     * ================================
     * @param int $id - Marketing Seller id
     * ================================
     */
    function view($id){
    	
    	// Get extension... pdf, json, xml, etc.
        $ext = $this->request->params['ext'];
        // Basic get of info, given Certificate ID.
        $certificate = $this->Certificate->findById($id);
		
        if('pdf' === $ext){

        	header("Pragma: no-cache");
            // Import Buyers model
            App::import('Model','Buyer');
            $this->Buyer = new Buyer();
            $buyer_id = $certificate['Certificates']['buyer_id'];
            $buyer = $this->Buyer->findById( $buyer_id, array('account_id') ); //Get Account ID
            $account_id = $buyer['Buyers']['account_id'];
        	
			// File Repo <account_id>/<buyer_id>/<certificate_id>.pdf
        	$pdf = BASE_REPO."/".$account_id."/".$buyer_id."/".$id.".pdf";

        	if (file_exists($pdf) && is_readable($pdf)) {

                $path_info   = pathinfo($pdf);
                $file_handle = fopen($pdf, "rb");
                $file_name = $path_info['basename'];
        	    $contents =  fread($file_handle, filesize($pdf));
        	    fclose($file_handle);
                $fn = (isset($file_name)) ? $file_name : "certificate_file.pdf";
                // Set Headers for PDF, and export.
                header("Content-type: application/pdf");
                header("Content-Disposition: attachment; filename=\"$fn\"");
                echo $contents;
            }
        } else {
        	$this->set('results',json_encode($certificate));
        }
    }
    
    /*
     * -----------------------------------------------------
     * edit($id)
     * -----------------------------------------------------
     * HTTP Request - PUT/POST
     * 
     * Edits Current Marketing Seller Data.
     * 
     * HTTP PUT/POST Request Example: 
     *     .../certificates/$id.json
     *     
     *     => Maps To: BuyersController::edit($id)
     *     => .json extension maps to app/View/Certificates/json/edit.ctp
     *     
     * ================================
     * @param int $id - Marketing Seller of given id to edit.
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
        $this->Certificate->id = $id;
        
        // Loop through and process query parameters.
        foreach ($query_params as $key => $val){
            
            if(array_search($key, $this->Certificate->valid_params) === FALSE){
                // Return (400) Bad Request code.
                $code = $this->setErrorCode(HTTP_BAD_REQUEST);
                $code['additional'] = 'Invalid query parameter.';
                $this->set('results',json_encode($code));
                return;
            }
            
            $this->Certificate->saveField($key,$val);

        }
        
        // Build Single-Resource output.
        // Set Single-Resource URL.
        $user = $this->Certificate->findById($id);
        $user['Certificate']['url'] = $this->Certificate->base_url."/".$this->Certificate->model."/".$id.'.json';
        
        // This is done for easier compaction of json data.
        $Certificate = $user['Certificate'];

        // Set Success Error code, and output results.
        $code = $this->setErrorCode(HTTP_OK);
        $results = compact('Certificate','code');
        $this->set('results',json_encode($results));
    }
    
    /*
     * -----------------------------------------------------
     * add()
     * -----------------------------------------------------
     * HTTP Request - POST
     * 
     * Add a Marketing Seller given information in request
     * 
     * Query Params allowed => ( 'name','attn_name','address_line1',
     *                           'address_line2','city','state','initials',
     *                           'zip', 'phone_number', 'fax_number', 'email')
     * 
     * HTTP POST Request Example: 
     *     .../certificates.json
     *     
     *     => Maps To: BuyersController::add()
     *     => .json extension maps to app/View/Certificates/json/add.ctp
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
        $this->Certificate->create();
        
        foreach ($query_params as $key => $val){
            if(array_search($key, $this->Certificate->valid_params) === FALSE){
                // Return (400) Bad Request code.
                $code = $this->setErrorCode(HTTP_BAD_REQUEST);
                $code['additional'] = 'Invalid query parameter.';
                $this->set('results',json_encode($code));
                return;
            }
            if($key == 'taxcode_id'){
            	$this->Certificate->set('expected_tax_code_id',$val);
            	$this->Certificate->set('actual_tax_code_id',$val);
            } else if($key == 'zone_id'){
            	$this->Certificate->set('exposure_zone_id',$val);
            } else {
                $this->Certificate->set($key,$val);
            }
        }
        
        try{
            
            $this->Certificate->save();
            $id = $this->Certificate->getLastInsertID();
            $q_result = $this->Certificate->query("SELECT * FROM certificates WHERE id=".$id);
            $certificate = $q_result[0][0]; 
        } catch (Exception $e){
            //Throw (400) Bad request error.
            $code = $this->setErrorCode(HTTP_CONFLICT);
            $this->set('results',json_encode($code));
            return;
        }
        
        // Build Single-Resource output.
        // Set Single-Resource URL.
        $certificate['url'] = $this->Certificate->base_url."/".$this->Certificate->model."/".$certificate['id'].'.json';

        // Set Success Error code, and output results.
        $code = $this->setErrorCode(HTTP_OK);
        $results = compact('certificate','code');
        $this->set('results',json_encode($results));
    }
    
    /*
     * -----------------------------------------------------
     * delete()
     * -----------------------------------------------------
     * HTTP Request - DELETE
     * 
     * Deletes Marketing Seller of given id.
     * 
     * HTTP DELETE Request Example: 
     *     .../certificates/123.json
     *     
     *     => Maps To: BuyersController::delete($id)
     *     => .json extension maps to app/View/Certificates/json/delete.ctp
     *     
     * ================================
     * @param int $id - Marketing Seller of given id to delete.
     * ================================   
     */
    function delete($id){
        // Delete a resource.
        // Success -> set $results.
        // Fail -> Set $code with error code. 
        try{
            $this->Certificate->delete($id);
            $code = $this->setErrorCode(HTTP_OK);
            $this->set('results',json_encode($code));
        } catch (Exception $e){
            $code = $this->setErrorCode(HTTP_BAD_REQUEST);
            $this->set('code',json_encode($code));
        }
    }

}


?>