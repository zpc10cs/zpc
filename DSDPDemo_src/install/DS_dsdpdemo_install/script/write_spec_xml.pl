#!/usr/bin/perl -w
#name:write_spec_xml.pl filename node1name/nodename2/nodename3  "keyname=keyvalue" newvalue is to read the node value
#name:write_spec_xml.pl filename node1name/nodename2/nodename3 "attrname"  "keyattrname=keyattrvalue" newvalue is to read the attr value
use XML::DOM;
#use XML::Dumper;
my ($FileName,$NodeTree,$attrname,$KeyString,$newvalue);
if(@ARGV == 4)
{
    $FileName =$ARGV[0];
    $NodeTree =$ARGV[1];
    $KeyString=$ARGV[2];
    $newvalue =$ARGV[3];
}
elsif(@ARGV == 5)
{
    $FileName =$ARGV[0];
    $NodeTree =$ARGV[1];
    $attrname =$ARGV[2];
    $KeyString=$ARGV[3];
    $newvalue =$ARGV[4];
}
else
{
    printf("The num of param is error.\n");
    #log
    exit;
}		
	
if(!(-e $FileName))
{
    #printf("Fail to read the xml:".$FileName.",because it doesn't exist!\n");
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
    setText($nodename[0],$doc);
}
else
{	
    setAttr($nodename[0],$doc);
}
$doc->printToFile ("$FileName");

exit;

sub setText
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
        $nodelist->item($i)->getElementsByTagName($nodename[$NUM-1])->item(0)->getFirstChild->setData($newvalue);
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
        my $node=$nodelist->item(0);
        $doc=$node;
        setText($nodename[$k],$doc);	
    } 		
}

sub setAttr
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
            my $href=$nodelist->item($i)->getAttributeNode($key);
            if(!defined($href))
            {
            	next;
            }
            my $tmpvalue=$href->getValue;	
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
        $nodelist->item($i)->setAttribute($attrname,$newvalue);
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
        $node=$nodelist->item(0);  
        $doc=$node;
        setAttr($nodename[$k],$doc);	
    } 		  
}	

