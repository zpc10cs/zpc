#!/usr/bin/perl -w
#name:read_special_xml.pl filename node1name/nodename2/nodename3  "keyname=keyvalue" is to read the node value
#name:read_special_xml.pl filename node1name/nodename2/nodename3 "attrname"  "keyattrname=keyattrvalue"is to read the attr value
use XML::DOM;
#use XML::Dumper;
my ($FileName,$NodeTree,$attrname,$KeyString);
if(@ARGV == 3)
{
    $FileName =$ARGV[0];
    $NodeTree =$ARGV[1];
    $KeyString=$ARGV[2];
}
elsif(@ARGV == 4)
{
    $FileName =$ARGV[0];
    $NodeTree =$ARGV[1];
    $attrname =$ARGV[2];
    $KeyString=$ARGV[3]; 
}
else
{
    printf("The num of param is error.\n");
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

my @nodename=split("/",$NodeTree);
my @KeyValue=split("=",$KeyString);
if(@KeyValue != 2)
{
    printf("The second param is error,it should be name=value,and the value can not contain \"=\".\n");
    #log
    exit;
}	
my $key  =$KeyValue[0];
my $value=$KeyValue[1];
my $k=0;
my $NUM=@nodename;
my $flag=0;
if(!defined($attrname))
{
    $Rst=getText($nodename[0],$doc);
}
else
{	
    $Rst=getAttr($nodename[0],$doc);
}	
printf($Rst."\n");
exit;

sub getText
{
    $k++;
    my ($nodename,$doc)=@_;
    if($k == $NUM-1)
    {
        $nodelist=$doc->getElementsByTagName($nodename);
        my $len=$nodelist->getLength;
        my $i;
        for($i=0;$i<$len;$i++)
        {
            my $tmpvalue=$nodelist->item($i)->getElementsByTagName($key)->item(0)->getFirstChild->getData;
            if($tmpvalue eq $value)
            {
            	last;
            }
        }
        my $Rst=$nodelist->item($i)->getElementsByTagName($nodename[$NUM-1])->item(0)->getFirstChild->getData;
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
        my $node=$nodelist->item(0);
        $doc=$node;
        getText($nodename[$k],$doc);	
    } 		
}

sub getAttr
{
    $k++;
    my ($nodename,$doc)=@_;
    if($k == $NUM)
    {
        $nodelist=$doc->getElementsByTagName($nodename);
    	if(!defined($nodelist))
    	{
    	    printf("Fail to get the nodename:".$nodename.",because it doesn't exist!\n");
    	    #log
    	    exit;
    	}
        my $len=$nodelist->getLength;
        my $i;
        for($i=0;$i<$len;$i++)
        {
            my $tmpvalue=$nodelist->item($i)->getAttributeNode($key)->getValue;
            if($tmpvalue eq $value)
            {
                $flag=1;
            	last;
            }
        }
        if($flag != 1)
        {
            printf("Fail to read the attr value,because the key attr is error!\n");
            #log
            exit;
        }	
        my $Rst=$nodelist->item($i)->getAttributeNode($attrname)->getValue;
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
        $node=$nodelist->item(0);  
        $doc=$node;
        getAttr($nodename[$k],$doc);	
    } 		  
}	

