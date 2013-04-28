<?php

App::import('Model','RestCollectionClustered');

/**
 * Certificate model for CertCapture.
 * 
 * This class is used to resemble a Certificate in AvaCertExpress.
 * 
 * Extends and Inherits from the RestCollectionClustered model class.
 * 
 * Updated: 03/28/2013
 * Updated By: Colin Craig <colin.craig@avalara.com>
 * 
 */
                
class Certificate extends RestCollectionClustered {
    
    public function __construct() {
        
        // DB Configuration.
        $this->useTable       = 'certificates';
        $this->name           = 'Certificates';
        $this->central_db     = false;
        
        // List of valid url params.
        $this->valid_params   = array( 'buyer_id','seller_id','zone_id','zone','signed_date',
                                       'expiration_date','filename','taxcode_id',
                                       'expected_tax_code_id','phone_number', 'address_line1', 'tag'
                                     );
    
        // Base URL of server. To be moved to Config file.
        $this->base_url       = "http://backend.ace.certcapture.net/";
    
        // Specifics about model and data type.
        $this->model          = "certificates";
        $this->extension      = ".json";
        $this->html_paginator = "&page=";
        $this->sort_params    = array('expiration_date','signed_date','modified','created');
        
        // This Model Property contains the tables, and an array
        // containing the type of join, and the fields to be joined on.
        $this->join_fields    = array( 'buyers'         => array('INNER','buyer_id'),
                                       'sellers'        => array('INNER','seller_id'),
                                       'tax_codes'      => array('INNER','expected_tax_code_id'),
                                       'exposure_zones' => array('INNER','exposure_zone_id')
                                     );
        
        // These are additional get parameters, and they detail the
        // Associations of Certificate with other models.
        // each is keyed on parameter with a value indicating whether
        // it is an Integer or a charvar.
        $this->associations   = array(
                                    'certificates'   => array(
                                                            'id'                   => true,
                                                            'expected_tax_code_id' => true,
                                                            'buyer_id'             => true,
                                                            'signed_date'          => false,
                                                            'expiration_date'      => false,
                                                            'exposure_zone_id'     => true ),
                                    'buyers'         => array(
                                                            'name'                 => false,  
                                                            'email'                => false,
                                                            'account_id'           => true,
                                                            'phone_number'         => false,
                                                            'address_line1'        => false ),
                                    'sellers'        => array(
                                                            'seller_number'        => false ),
                                    'tax_codes'      => array(
                                                            'name'                 => false ),
                                    'exposure_zones' => array(
                                                            'tag'                  => false )
                                 );
                    
        // This table stores information for simplified return data...
        // ie. If a tax code is needed, then instead of 'expected_tax_code_id'
        //     being returned, 'taxcode_id' is returned. Vice Versa...
        //     If 'tax_codes' is a requested table, then in the output
        //     'taxcode' will be defined.                          
        $this->lookUp = array( 'expected_tax_code_id' => 'taxcode_id', 
                               'exposure_zone_id'     => 'zone_id',
                               'exposure_zones'       => 'zone',
                               'tax_codes'            => 'taxcode' );

        parent::__construct();
    }

}
  
?>