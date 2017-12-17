#!/usr/bin/perl -w
#name:write_xml.pl filename node:attrname="value"]/subnode:attrname="value"  newvalue :is to write the node value
#name:read_xml.pl filename node:attrname="value"]/subnode:attrname newvalue : is to write the attr value
use XML::DOM;
#use XML::Dumper;
if(@ARGV != 3)
{
    printf("the num of parms is not three\n");
    #log
    exit;
}	
my $FileName=$ARGV[0];
my $NodeTree=$ARGV[1];
my $newValue=$ARGV[2];
my (@NodeNameRst,@NodeAttrRst,@AttrValueRst);
if(!(-e $FileName))
{
    printf("Fail to get the file:".$FileName.",because it doesn't exist!\n");
    #log
    exit;
}
my $parser= new XML::DOM::Parser;      
my $doc=$parser->parsefile($FileName);

my @node=split("/",$NodeTree);
my $read_flag=1;
for(my $i=0;$i<@node;$i++)
{
    my $nodename;	
    my $attrname;
    my $attrvalue;
    my @node2=split("<",$node[$i]);
    if(scalar(@node2) != 2)
    {
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
    setAttrValue($NodeNameRst[0],$NodeAttrRst[0],$AttrValueRst[0],$doc);
}
else
{	
    setNodeData($NodeNameRst[0],$NodeAttrRst[0],$AttrValueRst[0],$doc);
}

$doc->printToFile ("$FileName");

exit;


#这个是修改最底层节点值的方法，该方法要求参数格式为:节点名：属性名=值/节点名：属性名=值
sub setNodeData
{
    $k++;
    my ($nodename,$attrname,$attrvalue,$doc)=@_;
    if($k == $NUM+1)
    {
        $doc->getFirstChild->setData($newValue);
        return ;
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
    	$n=$nodelist->getLength;
    	$flag=0;
    	if(defined($attrname) && ($attrname ne "***"))
    	{
    	    for(my $i=0;$i<$n;$i++)
    	    {
    	        $node=$nodelist->item($i);
    	        $href=$node->getAttributeNode($attrname);
    	        if(!defined($href))
    	        {
    	          next;
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
        setNodeData($NodeNameRst[$k],$NodeAttrRst[$k],$AttrValueRst[$k],$doc);	
    } 		
}	

#这个是修改最底层节点值的方法，该方法要求参数格式为:节点名：属性名=值/节点名：属性名
sub setAttrValue
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
        $n=$nodelist->getLength;
        if($n > 1)
        {
            printf("match so many!\n");
            #log
            exit;
        }
        else
        {
            $node=$nodelist->item(0);
            $node->setAttribute($attrname,$newValue);
            return ;
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
    	$n=$nodelist->getLength;
    	$flag=0;
        if(defined($attrname) && ($attrname ne "***"))
        {
    	    for(my $i=0;$i<$n;$i++)
    	    {
    	        $node=$nodelist->item($i);
    	        $href=$node->getAttributeNode($attrname);
    	        if(!defined($href))
    	        {
    	            printf("Fail to get the attr:".$attrname.",because it doesn't exist!\n");
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
        setAttrValue($NodeNameRst[$k],$NodeAttrRst[$k],$AttrValueRst[$k],$doc);	
    } 		   
}	



             

