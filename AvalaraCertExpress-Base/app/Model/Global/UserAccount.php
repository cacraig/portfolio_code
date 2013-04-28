<?php

App::import('Model','RestCollection');

/**
 * UserAccount model for CertCapture.
 * 
 * This class is used to resemble a global user account in AvaCertExpress.
 * 
 * Extends and Inherits from the RestCollection model class.
 * 
 * Updated: 03/21/2013
 * Updated By: Colin Craig <colin.craig@avalara.com>
 * 
 */
                
class UserAccount extends RestCollection {
	
    public function __construct() {
    	
        $this->useTable       = 'user_accounts';
        $this->name           = 'UserAccount';
        $this->central_db     = true;
        $this->valid_params   = array( 'name','email','phone','user_role_id','billing_tier_id','active' );
    
        // Base URL of server. To be moved to Config file.
        $this->base_url       = "http://backend.ace.certcapture.net/";
    
                // The parameters to be retrieved and returned.
        $this->associations   = array(
                                    'user_accounts' => array(
                                                            'id'                   => true,
                                                            'name'                 => false,  
                                                            'email'                => false,
                                                            'phone'                => false )
                                     );
        // Specifics about model and data type.
        $this->model          = "user_accounts";
        $this->extension      = ".json";
        $this->html_paginator = "page=";

        parent::__construct();
    }
}
  
?>