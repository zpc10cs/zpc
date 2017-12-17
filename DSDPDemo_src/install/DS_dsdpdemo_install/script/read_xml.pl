#!/usr/bin/perl -w
#name:read_xml.pl filename node<attrname="value">/subnode<attrname="value"> is to read the node value
#name:read_xml.pl filename node<attrname="value">/subnode<attrname> is to read the attr value
use XML::DOM;
#use XML::Dumper;

my $FileName=$ARGV[0];
my $NodeTree=$ARGV[1];
my (@NodeNameRst,@NodeAttrRst,@AttrValueRst);
if(@ARGV != 2)
{
    printf("This script need 2 parms.\n");
    #log
    exit;
}	
if(!(-e $FileName))
{
    printf("Fail to read the xml:".$FileName.",because it doesn't exist!\n");
    #log
    exit;
}
my $parser= new XML::DOM::Parser;      
my $doc=$parser->parsefile($FileName);

my @node=split("/",$NodeTree);	
my $read_flag=1;
my $n=0;
my $a=0;
my $v=0;

for(my $i=0;$i<@node;$i++)
{
    my $nodename;	
    my $attrname;
    my $attrvalue;
    my @node2=split("<",$node[$i]);
    if(scalar(@node2) != 2)
    {
    	#printf("the node has no attribute\n");
    	#log
    	printf("The second parm is error\n");
    	exit;
    }
    $nodename=$node2[0];
    my @temp=split(">",$node2[1]);
    if(!defined($temp[0]))
    {
    	$attrname="***";
    	$attrvalue="***";
    }	
    else
    {
    	my @node3=split("=",$temp[0]);
        if(scalar(@node3) == 1)
        {
    	   $attrname=$node3[0];
    	   $attrvalue="***";
        }	
        else
        {
    	    $attrname=$node3[0];
    	    my $tmp="";
    	    for(my $m=1;$m<@node3;$m++)
    	    {
    	        if($m == scalar(@node3)-1)
    	        {
    		    $tmp=$tmp.$node3[$m];
    	        } 
    	        else
    	        {
    	    	    $tmp=$tmp.$node3[$m]."=";
    	        }	
    	    }
    	    $attrvalue=$tmp;  
        }
    }    
    if($i == @node-1)
    {
        if((($attrvalue eq "***") && ($attrname eq "***")) || ( defined($attrname) && defined($attrvalue) && ($attrvalue ne "***") ) )
        {
    	    $read_flag=0;
    	}
    }	

    push(@NodeNameRst,$nodename);
    push(@NodeAttrRst,$attrname);
    push(@AttrValueRst,$attrvalue);
}
my $k=0;
my $NUM=@NodeNameRst;
my $Rst;
if($read_flag == 1)
{
    $Rst=getAttrValue($NodeNameRst[0],$NodeAttrRst[0],$AttrValueRst[0],$doc);
}
else
{	
    $Rst=getNodeData($NodeNameRst[0],$NodeAttrRst[0],$AttrValueRst[0],$doc);
}
printf($Rst."\n");
exit;


#这个是获取最底层节点值的方法，该方法要求参数格式为:节点名：属性名=值/节点名：属性名=值
sub getNodeData
{
    $k++;
    my ($nodename,$attrname,$attrvalue,$doc)=@_;
    if($k == $NUM+1)
    {
        my $Rst=$doc->getFirstChild->getData;
        return $Rst;
    }
    else
    {
        
    	$nodelist=$doc->getElementsByTagName($nodename);
    	if(!defined($nodelist))
    	{
    	    printf("Fail to get the nodename:".$nodename.",because it doesn't exist!\n");
    	    #log
    	    exit;
    	}	 
    	$count=$nodelist->getLength;
    	$flag=0;
    	if(defined($attrname) && ($attrname ne "***"))
    	{
    	   #$n++;
    	   #$a++;
    	   #$v++;
    	   for(my $i=0;$i<$count;$i++)
    	   {
    	      $node=$nodelist->item($i);
    	      $href=$node->getAttributeNode($attrname);
    	      if(!defined($href))
    	      {
    	      	 printf("Fail to get the attr:".$attrname." in xml,because it doesn't exist!\n");
    	      	 #log
    	      	 exit;
    	      }	
    	      $value=$href->getValue;
    	      if($value eq $attrvalue)
    	      {
    	    	 #$flag=1; 
    	    	 last;
    	      }
    	      else
    	      {
    	    	 next;
    	      }		
           }
        }
        else
        {
            #$flag=1;
            #$n++;
            $nodelist=$doc->getElementsByTagName($nodename);
    	    if(!defined($nodelist))
    	    {
    	        printf("Fail to get the nodename:".$nodename.",because it doesn't exist!\n");
    	        #log
    	        exit;
    	    }
            $node=$nodelist->item(0);
        }
        $doc=$node;
        getNodeData($NodeNameRst[$k],$NodeAttrRst[$k],$AttrValueRst[$k],$doc);	
    } 		
}	

#这个是获取最底层节点值的方法，该方法要求参数格式为:节点名：属性名=值/节点名：属性名
sub getAttrValue
{
    $k++;
    my ($nodename,$attrname,$attrvalue,$doc)=@_;
    if($k == $NUM)
    {
        $nodelist=$doc->getElementsByTagName($nodename);
    	if(!defined($nodelist))
    	{
    	    printf("Fail to get the nodename:".$nodename.",because it doesn't exist!\n");
    	    #log
    	    exit;
    	}
        $count=$nodelist->getLength;
        if($count > 1)
        {
            printf("match so many!\n");
            #log
            exit;
        }
        else
        {
            $node=$nodelist->item(0);
            $href=$node->getAttributeNode($attrname);
    	    if(!defined($href))
    	    {
    	        printf("Fail to get the attr:".$attrname." in xml,because it doesn't exist!\n");
    	      	#log
    	      	exit;
    	    }	
            $Rst=$href->getValue;
            return $Rst;
        }	
    }
    else
    {
    	$nodelist=$doc->getElementsByTagName($nodename);
    	if(!defined($nodelist))
    	{
    	    printf("Fail to get the nodename:".$nodename.",because it doesn't exist!\n");
    	    #log
    	    exit;
    	}	 
    	$count=$nodelist->getLength;
        $flag=0;
        if(defined($attrname) && ($attrname ne "***"))
        {
    	    for(my $i=0;$i<$count;$i++)
    	    {
    	        $node=$nodelist->item($i);
    	        $href=$node->getAttributeNode($attrname);
    	        if(!defined($href))
    	        {
    	      	    printf("Fail to get the attr:".$attrname." in xml,because it doesn't exist!\n");
    	      	    #log
    	      	    exit;
    	        }	
    	        $value=$href->getValue;
    	        if($value eq $attrvalue)
    	        {
    	    	    #$flag=1; 
    	    	    last;
    	        }
    	        else
    	        {
    	    	    next;
    	        }		
            }
        }
        else
        {
            $nodelist=$doc->getElementsByTagName($nodename);
    	    if(!defined($nodelist))
    	    {
    	        printf("Fail to get the nodename:".$nodename.",because it doesn't exist!\n");
    	        #log
    	        exit;
    	    }
            $node=$nodelist->item(0);
        }    
        $doc=$node;
        getAttrValue($NodeNameRst[$k],$NodeAttrRst[$k],$AttrValueRst[$k],$doc);	
    } 		  
}	



                                                            

