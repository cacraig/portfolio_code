<?php

/**
 * Global RestCollection Model class for Avalara CertExpress.
 * 
 * This class acts defines the default core functionality of the
 * Collections REST API requests for Global models. 
 * 
 * Updated: 3/27/13
 * 
 * Created by: Colin Craig
 */
class RestCollection extends AppModel {
	public $useTable = false;
    public $name = 'RestCollection';
    //public $useDbConfig = 'default';
    
    /*Default Attributes*/
    
    // Parameters to retrieve
    public $get_params        = array('email','name');
    
    // Valid (parameters allowed)
    public $valid_params      = array('name','email','phone','user_role_id','billing_tier_id','active');
    
    // Base URL of server. To be moved to Config file.
    public $base_url          = "http://backend.ace.certcapture.net/";
    
    // Specifics about model and data type.
    public $model             = "user_accounts";
    public $extension         = ".json";
    public $html_paginator    = "&page=";
    public $abs_query_params  = array();
    public $search_style      = 'ILIKE'; //Defines what kind of param/search matching should be done.
    public $associations      = array();
    public $join_fields       = array();
    /********************/
    
   /*
    * Default Constructor for RestCollection Object.
    */
    public function __construct() {
    	
    	parent::__construct();
    }
    
    
   /**
    * ---------------------------------------------------------------------------
    * findDefaultCollection($query_params, $page, $limit)
    * ---------------------------------------------------------------------------
    * 
    * Builds and executes Default Collection query, and returns results. 
    * This is only executed if user specifies a page and/or limit, but does not
    * specify any additional parameters.
    * 
    * @access - public
    * ================================
    * @param int   $page -  Current Page Number.
    * @param int   $limit - Max number of returned entries.
    * ================================
    * 
    */
    public function findDefaultCollection($page,$limit){
        
        // Set offset for pagination.
        $offset = ($page*$limit)-$limit;
        
        // Build Query string...essentially a paginated find-all
        $query_string  = $this->_build_base_query();
        if(null != $this->sort_param){
            $query_string .= " ORDER BY ".$this->model.".".$this->sort_param." ".$this->sort_order;
        }
        $query_string .= " LIMIT ".$limit." OFFSET ".$offset;

        // Get Data...
        $data = $this->query($query_string);

        //Results empty
        if(empty($data)){
            //Return No results status code.
            return $this->setErrorCode(HTTP_NO_CONTENT);
        }

        // Get total count.
        $count = $data[0][0]['count'];
    
        $total_pages = $this->_getTotalPages($count, $limit, $page);
    
        $results = $this->parse_results(&$data, $limit, $page, $total_pages);
        
        return $results;
    }
    
   /**
    * ---------------------------------------------------------------------------
    * findCollection($query_params, $page, $limit)
    * ---------------------------------------------------------------------------
    * 
    * Builds and executes Collection query, and returns results. 
    * 
    * @access - public
    * ================================
    * @param array $query_params - Array of Query string parameters.
    * @param int   $page -  Current Page Number.
    * @param int   $limit - Max number of returned entries.
    * ================================
    * 
    */
    public function findCollection($query_params, $page, $limit){

        $query_string = $this->_build_base_query(&$query_params);

        // Set offset for pagination.
        $offset = ($page*$limit)-$limit;

        if('ILIKE'== $this->search_style){
            // $query is set as a closure referencing a function returned by _ilikeFetchAll()
            // _ilikeFetchAll will also modify $query_string to handle an ILIKE prepared query.
            $query = $this->_ilikeFetchAll($query_string, $offset, $query_params, $limit);
        }elseif('EXACT'== $this->search_style){
            // TODO
            $query = ''; //Call builder function for exact query.
        }
        
        // Check to see if Bad request ... (Invalid Params)
        if(HTTP_BAD_REQUEST == $query){
            return $this->setErrorCode(HTTP_BAD_REQUEST);
        }
        
        // Since prepared_query_data was passed by reference, it was modified.
        // Execute Query
        $data = $this->getDataSource()->fetchAll($query_string, $query());

        //Results empty
        if(empty($data)){
            //Return No results status code.
            return $this->setErrorCode(HTTP_NO_CONTENT);
        }
    
        // Get total count.
        $count = $data[0][0]['count'];
        $total_pages = $this->_getTotalPages($count, $limit, $page);
        $results = $this->parse_results(&$data, $limit, $page, $total_pages);
    
        return $results;
    }
  
  /**
   * -----------------------------------------------
   * parse_results(&$data, $limit, $page, $total_pages)
   * -----------------------------------------------
   * Parses data into nicely formatted results...for better JSON!
   * 
   * @param reference &$data - Reference to query data.  
   * @param int $limit       - Max Entries per page.
   * @param int $page        - Current Page.
   * @param int $total_pages - Total number of pages.
   * 
   * @access Public
   * @return Array Results
   * 
   */
    public function parse_results(&$data, $limit, $page, $total_pages){
     
        // Build HTML base string for collection pagination...
        // contains all link info except for page and limit.
        $html_index_string = $this->_build_html_base();
        
        // Base string for view hrefs
        $html_view_string = $this->base_url.$this->model."/";

       /* Lambda that cross references the current page, 
        * the total number of pages, and whether a previous or next page 
        * link is reqested.
        * 
        * @return String 
        */
        $check_page = 
            function($html_index_string,$page, $total_pages, $page_iterator,$limit){
                if($page == $total_pages){
                    // Check to see if total pages != 1, and that a 
                    // previous page 
                    if($page_iterator == 'prev' && $total_pages != 1 && ($page-1) != 0){
                        return $html_index_string.($page-1)."&limit=".$limit;
                    
                    }
                    return "none";
                }
                else{
                    if($page_iterator == 'prev' && $total_pages != 1 && ($page-1) != 0){
                        return $html_index_string.($page-1)."&limit=".$limit;
                    }
                    elseif($page_iterator == 'next'){
                        // Replace with Base Repo
                        return $html_index_string.($page+1)."&limit=".$limit;
                    } else{
                        return "none";
                    }
                }
        };

       /* Lambda that simply builds view href's, and returns a simplified array.
        * 
        * This Lambda acts as the Mapper... to later be reduced. 
        * - RECURSIVE VERSION - (Better - but use non recursive if this is too buggy)
        * This solution makes me weep with joy. 
        * @return Array
        */
        
        $parse_data = 
            function( $html_view_string, $data, $extension) use (&$parse_data){
                $out = array();
                foreach ($data as $key => $val){
                    if(is_array($val)){
                       //Recursive Call.
                       $out[$key]= $parse_data($html_view_string, $val, $extension);
                    } else{
                       // Base Case
                       $out[$key] = $val;
                       // An identity comparison is neccessary to avoid
                       // crazy outcomes. ie. 
                       // 'id' == 0  evals to TRUE whereas
                       // 'id' === 0 evals to FALSE.
                       if('id' === $key){
                           // Set href for view.
                           $out['href'] =  $html_view_string.$val.$extension;
                       }elseif('count' === $key){
                           // Get rid of the side effect of Count window function.
                           unset($out[$key]);
                       }
                    }
                }
                return $out;
            };
            
        $data_results = array();
        $model = substr($this->model,0,-1); // Strip 's' off model for parse function.
        
       /* Lambda that "simply" builds view href's, and returns a simplified array.
        * It searches through this object's associations, and determines 
        * if a foriegn key exists. If it does, it builds an view-href for it.
        * 
        * - RECURSIVE VERSION -
        * This solution makes me weep with joy... and sorrow.
        * @return Array
        */

        $parse_data_advanced = 
            function($data, &$associations, $extension, $base_url) use (&$parse_data_advanced, &$data_results, $model){
                $out = array();
                foreach ($data as $key => $val){
                    if(is_array($val)){
                        //Recursive Call. 
                        $parse_data_advanced($val, &$associations, $extension, $base_url);
                    } else{
                        // Base Case
                        foreach($associations as $as => $af){
                            // This plural check is kept iterative, and not offloaded to a function
                            // in order to shorten the call stack. 
                            // For more intuitive indexing. certificates -> (certificate, buyer, seller)
                            if (preg_match('/[sxz]es$/', $as) OR preg_match('/[^aeioudgkprt]hes$/', $as)) {
                                // Remove "es"
                                $table = substr($as, 0, -2);
                            }
                            elseif (preg_match('/[^aeiou]ies$/', $as)) {
                                // Replace "ies" with "y"
                                $table = substr($as, 0, -3).'y';
                            }
                            elseif (substr($as, -1) === 's' AND substr($as, -2) !== 'ss') {
                                // Remove singular "s"
                                $table = substr($as, 0, -1);
                            }

                            foreach($af as $x=>$z){
                                // Sets href for main model.
                                if('id' === $x){
                                    $data_results[$data['id']][$table]['href'] = $base_url.$as."/".$data['id'].$extension;
                                }

                                $data_results[$data['id']][$table][$x] = $data[$x];
                            }
                            // Checks to see if an href is defined for
                            // all of the foriegn keys.
                            // Sets them if they are not set.
                            if(!empty($data_results[$data['id']][$model][$table."_id"])
                                   &&  empty($data_results[$data['id']][$as]['href'])){

                               $data_results[$data['id']][$table]['href'] = $base_url.$as."/"
                                                                         .$data_results[$data['id']][$model][substr($as, 0, -1)."_id"]
                                                                         .$extension;
                            }
                        }
                    }
                }
                return $data_results;
            };
            
        // Lambda - Combiner function for reduce()
        //          Merges two arrays.
        $merge =  
            function($ar1, $ar2) {  
                // Get all the words  
                $out = array_merge($ar1, $ar2);  
                return $out;  
            };

        //Organized results array. 
        if(!empty($this->associations)){
            // Associations defined, build nested json object.
            $parse_data_advanced($data,$this->associations,$this->extension,$this->base_url);
        } else {
            // Associations not defined, use old method. 
            $data_results = $this->reduce($merge,$parse_data($html_view_string,$data,$this->extension));
        }

        $results = array( 
            'count'          => $data[0][0]['count'],
            'current_page'   => $page,
            'next_page'      => $check_page($html_index_string,$page,$total_pages,'next',$limit),
            'previous_page'  => $check_page($html_index_string,$page,$total_pages,'prev',$limit),
            $this->model     => $data_results
        );

        return $results;
  }
  
   /**
    * ------------------------------------------------------
    * _getTotalPages ($count, $limit, $page)
    * ------------------------------------------------------
    * 
    * Retrieves total number of 'pages' of a given collection.
    * 
    * @param  int $count - Total number of results.
    * @param  int $limit - Max entries per page.
    * @param  int $page  - Current page number.
    * 
    * @access Private
    * @return int $total_pages - Total Number of 'pages'.
    */
    private function _getTotalPages ($count, $limit, $page){
    
        // Get total number of pages. 
        if( $count > 0 ) {
            $total_pages = ceil($count/$limit);
        } else {
            $total_pages = 0;
        }
        if ($page > $total_pages) {
            $page=$total_pages;
        }
    
        return $total_pages; 
    }
  
   /**
    * --------------------------------------------------------
    * _ilikeFetchAll($query_string, $structure_vars)
    * --------------------------------------------------------
    * Appends WHERE vars onto $query_string with ILIKE specified
    * for Approximate matching, and the query is put into prepared statement style...
    * 
    * ie.
    * 
    * SELECT * FROM cats WHERE name ILIKE :name AND species ILIKE :species; 
    * 
    * Returns a Closure that:
    * Appends %...% to all vals in array keyed on parameters for ILIKE,
    * and then returns the array of prepared query variables. 
    * 
    * ie. 
    * 
    * SELECT * FROM cats WHERE name ILIKE '%Bubbles%' AND species ILIKE '%Maine Coon%'; 
    * 
    * @access Private
    * 
    * @return Closure [using] reference to $structure_vars
    * 
    */
    private function _ilikeFetchAll(&$query_string, $offset,$query_params, $limit){
        
        //Prepare query 
        $keys = array_keys($query_params);

        foreach ($query_params as $key => $val){
        
            //Asert that parameter given exists within allowed parameters.
            if(array_search($key, $this->valid_params) === FALSE){
                // Return (400) Bad Request code.
                return HTTP_BAD_REQUEST;
            }
            
            //If it is an integer, use = becaue ILIKE does not work with integers.
            foreach($this->associations as $k => $v){
                if(isset($v[$key])){
                   if(!$v[$key]){
                        $prepared_query_data[$key] = $val;
                        $query_string .= " AND ".$k.".".$key." ILIKE :".$key;
                   } else {
                        $query_string .= " AND ".$k.".".$key."= ".$val;
                   }
                }
            }

        }
        // Set Sort by Param.
        if(null != $this->sort_param){
            $query_string .= " ORDER BY ".$this->model.".".$this->sort_param." ".$this->sort_order;
        }

        // Specify limit and offset.
        $query_string .= " LIMIT ".$limit." OFFSET ".$offset;
        // Closure
        // @param  String  $type -Wildcard specifier 
        //                          ie. %_% for '%name%', %_ for '%name'
        return function($type = '%_%') use (&$prepared_query_data) {
                   if(empty($prepared_query_data)){
                       return;
                   }
                   switch($type){
                       case '%_%':
                           foreach ($prepared_query_data as $key => $val){
                                $prepared_query_data[$key] = '%'.$val.'%';
                           }
                       break;
                       case '%_':
                           foreach ($prepared_query_data as $key => $val){
                               $prepared_query_data[$key] = '%'.$val;
                           }
                       break;
                       case '_%':
                           foreach ($prepared_query_data as $key => $val){
                               $prepared_query_data[$key] = $val.'%';
                           }
                       break;
                   }

                   return $prepared_query_data;
                };
    }
    
    /**
     * ------------------------------------------------------
     * _build_base_query
     * ------------------------------------------------------
     * Processes this objects 'get_params' and build out a base query.
     *
     *
     * @access  Private
     * @param   (Optional) Array Reference - $query_params
     * @return  String - Base Query.
     *
     */
    private function _build_base_query(&$query_params = null){
    
        $str  = "SELECT ";
        $this->_add_sql_params(&$str); // Adds SQL aliases... a.something AS a 
        $str .= "count(*) OVER() AS count"; 

        // Checks to see if buyers, sellers, tax codes, and exposure zones data is needed.
        $str .=     " from ".$this->model;
        foreach($this->join_fields as $key => $val){
            $str .= " ".$val[0]." JOIN ".$key." ON (".$this->model.".".$val[1]." = ".$key.".id)";
        }

        $str .= " WHERE true ";

        return $str;
    }
    
   /**
    * ---------------------------------------------------------------------
    * _build_html_base()
    * ---------------------------------------------------------------------
    * 
    * Simply builds the html base string for pagination linking. 
    * 
    * @return String $html_base_string - HTML base string for link.
    * 
    */
    private function _build_html_base(){
        //Build HTML base string particular to this Collection.
        
        $html_base_string =  $this->base_url.$this->model.$this->extension."?";
        foreach($this->abs_query_params as $aqp => $value){
            $html_base_string .= "&".$aqp."=".$value;
        }
        $html_base_string .= $this->html_paginator;
        
        return $html_base_string;
    }
    
    /**
     * -------------------------------------
     * reduce($combiner, $data, $identity)
     * -------------------------------------
     * 
     * Joins array data to topmost level index. 
     * 
     * (
     *    [0] => Array
     *        (
     *            [0] => Array
     *                (
     *                    [id] => 1
     *                    [name] => blah
     *                    [address_line1] => 123 Lane
     *                )
     *
     *        )
     *
     * )
     * 
     * Reduces to:
     * 
     *  (
     *      [0] => Array
     *          (
     *              [id] => 1
     *              [name] => blah
     *              [address_line1] => 123 Lane
     *          )
     *  )
     *  
     * @param   $combiner  lambda  - Merge function.
     * @param   $data      array   - Array of data to be reduced.
     * @return  Array  -  Either an empty array or $data reduced indexes.
     */
    public function reduce($combiner, $data){

        return !empty($data) ?    $combiner($this->_first($data),  
                                      $this->reduce($combiner, $this->_rest($data)))  
                                  :  array();  
    }
    
    /**
     * -------------------------------------------
     * _first($data)
     * -------------------------------------------
     * 
     * @access Private
     * @param  $data   array   - Array of Data.
     * @return First element of an array OR null.
     */

    private function _first($data) {   
        
        return empty($data) ? null : $data[0];  
    }  
  
    /**
     * -------------------------------------------
     * _rest($data)
     * -------------------------------------------
     * 
     * @access  Private
     * @param   $data    array   - Array of Data.
     * @return  Array of data including Everything after the first element of an array 
     * 
     */
    private function _rest($data) {  
        
        $out = $data;  
        if(!empty($out)) { array_shift($out); }  
        return $out;  
    }
    
    /**
     * -------------------------------------------------
     * _add_sql_params(&$str
     * -------------------------------------------------
     * Processes this object's 'associations' and builds out a base query.
     * 
     * @Override  RestCollectionClusered->_add_sql_params(&$str)
     * @param     String Reference      $str
     * @access    Private
     */  
    private function _add_sql_params(&$str){
        
        // Build Get params for Associated data.
        
        foreach($this->associations as $k => $v){

            // Build AS clause for each parameter.
            foreach($v as $x => $z){
                $param = explode('_',$x);
                if('id' == $x && $this->model != $k){
                    $str .= $k.".".$x." AS ".$k."_".$x.", ";
                } else {
                    $str .= $k.".".$x." AS ".$x.", ";
                }
            }
        }
        return;
    }
  
}
?>