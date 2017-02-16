##########################################################################################
## Behöver encoding tillvalet i varje sammanhang och tänkt på att examples måste vara
## inom två hashtags "##" för att fungera
##########################################################################################
##install.packages("RHTMLForms", repos = "http://www.omegahat.org/R", type = "source")
## xmlToDataFrame
## Some common pattern for search path

DATA			<- file.path(  getwd(), 'Data')
GRAF			<- file.path( getwd(),  "graf")


if( ! file.exists( DATA) ){
	dir.create( DATA, recursive = TRUE, showWarnings = FALSE )
}

if( !file.exists( GRAF) ){
	dir.create( GRAF, recursive = TRUE )
}

instant_pkgs <- function( pkgs ) 
	{ 
		pkgs_miss <- pkgs[which(!pkgs %in% installed.packages()[, 1])]
			if (length(pkgs_miss) > 0) 
			{
			install.packages(pkgs_miss)
				}

			if (length( pkgs_miss) == 0) 
			{
			message("\n ...Packages were already installed!\n")
			}
		# install packages not already loaded:    
	 # load packages not already loaded:
		attached <- search()
		attached_pkgs <- attached[grepl("package", attached)]
		need_to_attach <- pkgs[which(!pkgs %in% gsub("package:", "", attached_pkgs))]

		if (length(need_to_attach) > 0) 
		{
	for (i in 1:length(need_to_attach)) 
		require(need_to_attach[i], character.only = TRUE)
 		}

	if (length(need_to_attach) == 0) 
	{
	message("\n ...Packages were already loaded!\n")
	}
}
			



Fgrep	<- function( x , RegEx){
	if( !missing( RegEx )){
		Step1	<- grep(RegEx, x, value = TRUE)
		} else {
			Step1	<- x
		}
	NoMatch	<- paste0('\\b(tel|feed(s)?|mailto|javascript|twitter|facebook|linkedin|member|#|atom|printfriendly)\\b|/\\.[a-zA-Z]{1,1}/|(jpg|png|pdf|gif|jpeg|mp3|mp4)$')
	Step2	<- grep( NoMatch, Step1, invert = TRUE, value = TRUE)
	Step3	<- grep( paste0(NoMatch, "|#"), Step2, value = TRUE, invert = TRUE)
	return( unique( Step3 ))
}



getURIs <- 
function(uris, ..., multiHandle = getCurlMultiHandle(), .perform = TRUE, .multi = FALSE)
{
	content = list()
	curls = list()
	for( i in uris ) {
		curl	 	<- getCurlHandle()
		content[[i]] <- basicTextGatherer()
		opts <- curlOptions(URL = i, writefunction = content[[i]]$update, ...)
		curlSetOpt(.opts = opts, curl = curl)
		multiHandle = push(multiHandle, curl)
	}	
	complete(multiHandle)
	if( .perform && .multi ) {
		cores 	<- getOption("mc.cores", detectCores())
		cl		<- makeCluster( cores ) 
		clusterCall( cl, worker.init,  c('RCurl'))
		L	<- parLapply(cl, content, function(x) x$value())
		stopCluster(cl)
		return( L)
		} else if ( .perform && .multi == FALSE) {
			return( lapply(content, function(x) x$value()) )
		} else {
		return( list(multiHandle = multiHandle, content = content) )
	}
}



## Extract and save html file into dir, are used with <pageExtract>
## x is the url page that has to be retrived
## name is the dir that is created and where the 
## data is put into. Default is current dir with name = 'blogg'
webExtract		<- function( x, outPut = NULL, ... ){
		## partion the input url
		fileName	<-  gsub("http://(\\w+)", "\\1", x)
		dirName	<-  gsub("/","_", fileName ) 
		DATA		<- file.path(  getwd()	)
		if( is.null(outPut) ){
			outPut	<- "TopSales"
		}
		## Create dirname conditional on file input
		DIR			<- file.path( DATA, outPut, dirName )
		if( ! file.exists( DIR ) ){
			dir.create( path = DIR, recursive = TRUE, showWarnings = FALSE )	
		} 
		## Where to place the file
		f	<- CFILE( filename = file.path( DIR, paste0( dirName, ".html")), 'wb' )
		## Use input to get the html file 
		curlPerform( url = x, writedata = f@ref, .encoding = 'UTF-8',
					.opts = list( ssl.verifypeer = FALSE, connecttimeout = 30),
					followlocation = TRUE , ... ,maxredirs = 5)
		close( f )
}




readFile	<- function( x  ){
	## Read file and has to exists 
	stopifnot( file.exists( x ) )
	conn 	<- file( description =  x ,  open="r", encoding = "UTF-8")
	w		<- readLines( conn , encoding = "UTF-8")	
	w1		<- htmlTreeParse(w, error = function( ... ){ },
						useInternalNodes = TRUE, encoding = "utf8")
	close( conn )					
	return( w1 )
}

## Function for loading pkg for parallel enviornment
worker.init		<- function( pkg ){
	for( p in pkg ){
		library( p, character.only = TRUE)
	}
	NULL
}

get_A_tags		<- function( url )
			{
				Path	<- unlist(strsplit(url, "/") )
				Path2	<- paste0(Path[1], "//",  grep( "\\b(www|com|ca)\\b", Path, 
									value = TRUE))
				h		<- getCurlHandle( useragent = 'R', followlocation = TRUE,
								maxredirs = 5, connecttimeout = 25, 
								ssl.verifypeer = FALSE)					
				w		<- getURLContent( url, curl = h)
				if( inherits( w, "try-error") ) { 
						w2 <- NA
					} else {
					## Return as html object into R
					w1	<- htmlTreeParse(w, error = function( ... ){ },
								useInternalNodes = TRUE )
					## Extract only href from a tags			
					w2		<- 	xpathSApply( w1  , "//a", xmlGetAttr, "href")
					w2		<- Fgrep( w2 )
					Path2 	<- paste0(Path2, "/")	
					## Extend all the ones that doesn't have a http 
					## and starts with /			
					w2	<- gsub("^/", Path2 , w2) 				
					## Extend the ones that dont contaion http 
					w2	<- gsub( "^((?!http))", Path2 , w2, perl = TRUE )	
					w2		<- unique( w2 )
				}			
				return( w2 )
}



Format <- function( x, n, ... ) {
    Fun <- function( x, n,...) {
        Char 	<- prettyNum(	round(x), big.mark = " ",
                             nsmall = 0,scientific = FALSE,...)
        if( missing( n ) ){
            n <- nchar(Char)
            }
        R  <- sprintf( paste("%.", n, "s", sep = "") ,Char)
        return(R)
    }
    if( length( x ) > 1 ) {
        List <- sapply(x, Fun)
        return( List )
        } else {
            return( Fun( x , n,... ) )
            }
    }
    
##########################################################################################      
## Download pkg
pkg		<- c("XML", "tm", "RCurl", "RColorBrewer", "ggplot2",
			 "wordcloud", "grid", "timeDate", "data.table", "parallel",
			 "reshape")	 
## Om de inte finns installera dessa			 
instant_pkgs(pkg)
## Svenska språket
Sys.setlocale("LC_CTYPE", "sv_SE")
##########################################################################################	
#url = "http://web.archive.org/web/20120103123125/http://danwaldschmidt.com/blog/selfishness"
#url = "https://web.archive.org/web/*/http://danwaldschmidt.com/blog"	
url 	<- "http://topsalesworld.com/topsalesblogs/"
url <- "http://www.nasdaq.com/symbol/sbux/stock-report"
# Download html-script into Stock folder
webExtract( url, outPut = "Stock" )



FIL	<- list.files(recursive = TRUE, pattern = "nasdaq", full.names = TRUE)
		
Page		<- readFile( FIL )
Page1	<- getNodeSet(Page, "//table")




## Extract the 50 topbloggers
Page1	<- getNodeSet(Page, "//div[@class='top-blogger-floatleft']")
## Här har jag de 50 mest använda bloggarnas url
Url2		<- unlist( lapply( Page1, 
					function( x )  xmlSApply( x,  xmlGetAttr, "href")[[2]] ) )
Url3		<- do.call('rbind',lapply(strsplit( Url2, "/{1}"), 
					function( x ) grep("\\.(com|net|ca)", x , value = TRUE) )	)
					
Url3  <- Url3[!Url3 %in% c("www.caskeyone.com", "www.inc.com", "processspecialist.com", "scs-connect.com", "www.futureofsales.net")	]	



## Här har jag 					
## Spara varje blogg i en mapp och dess huvudfil 
## On error
# Url3	<- Url3[ ! Url3 %in% DIRS]
# Url2 	<- grep( paste0( Url3, collapse = "|"), Url2, value = TRUE)

Tid <- system.time({
	cores 	<- getOption("mc.cores", detectCores())
	cl		<- makeCluster( cores ) 
	clusterCall( cl, worker.init,  c('RCurl', 'XML'))
	## Används för lägga in webExtrac och data in i environmnet
	clusterExport(cl, c('webExtract','Url3'), envir = environment())
	parLapply(cl, 1:length( Url3 ), 
		function( x ) webExtract( Url3[x], outPut = "Data" ) )
	stopCluster(cl)
})[1:3]

cat( "The total amount of time using parallell is:\n ", rep("\t",9), Tid)


tmpFun		<- function( x ){
		if( x ==  ""){ 
			NA
		} else {
		w1	<- tryCatch(htmlParse(x, asText = TRUE, error = function( ... ){ },
								useInternalNodes = TRUE ),
								error = function( e ){
									NA
								})
								
					## Extract only href from a tags
		if( !is.na( w1)){						
			w2	<- xpathSApply( w1  , "//a", xmlGetAttr, "href")
			return( w2 )
		}	
		} 
	}



## Alla filer som finns i Data mappen 
FIL		<- 	list.files( path = DATA, recursive = TRUE, pattern = 'html', full.names = TRUE)
## Alla mappar i Data mappen
DIRS	<- dir( path = DATA)
## Used for information for each blogg like time 
Total1 <- 1
if( file.exists('Time.txt') ) file.remove('Time.txt')
Tid1 <- system.time({	
for( z in 1:length( DIRS )){
	Url3 <- NULL ; Url2 <- NULL ; Url1 <- NULL
	file1		<-  FIL[ z ]
	file2		<- suppressWarnings (readFile( file1 ) )
	## Grep all <a href>
	Step1		<- xpathSApply( file2  , "//a", xmlGetAttr, "href")
	Dir			<- unlist(strsplit(file1, "/")) 
	DirValue	<- grep("html", Dir)-1
	Match 		<- paste0("\\b(", Dir[ DirValue ], ")\\b")
	downPage	<- Fgrep( x = Step1, RegEx = Match)

	cat( "\t", Dir[ DirValue ] , " \n\t\tdirectory is currently in progress ")	
	
	
	downPage1	<- grep("(archive|page)(s)?",  downPage, value = TRUE, invert = TRUE)
	
	Tid2 <- system.time({
		if( length(downPage1) < 40 ){ 
			.multi = FALSE 
			} else {
			.multi = TRUE
			} 
			
		txt	<- getURIs( downPage1, .multi = .multi)
		
		Url	<- unlist(lapply( txt, 
							function(x)  tmpFun( x )))		
							
		Url1		<-  Fgrep( x = Url, RegEx = Match)
	
		Step2	<- unique(grep("archive(s)?", downPage1, value = TRUE ))
		if( length( Step2 ) == 1 ){
				txt		<- get_A_tags( Step2 )
				txt		<- txt[ !downPage1 %in% txt ]
				Time1	<- system.time({
				txt1	<- getURIs( txt, .multi = TRUE )
				})[1:3]
				cat(Step2, " time is: ", Time1, "\n")
				Url2	<- unlist(lapply( txt1, 
								function(x)  tmpFun( x )))
				Url2	<- Fgrep(x = Url2, RegEx = Match)
			} 		
		Step3	<- grep("page(s)?", downPage1, value = TRUE, perl =TRUE )[1]
		Step3	<- unique(gsub("/[1-9]+", "/%d", Step3))
			if( length( Step3 ) > 0 && !is.na( Step3 )){
				Step3	<- sprintf(paste0(Step3), 1:50)
				Time1	<- system.time({
				txt		<- getURIs( Step3, .multi = TRUE  )
				Url3	<- unlist(lapply( txt, 
									function(x)  tmpFun( x )))
				Url3	<- Fgrep(x = Url3, RegEx = Match)
			})[1:3]
			cat(Step2, " time is: ", Time1, "\n")
		}					
	Url4	<- unique(c(Url3, Url2, Url1 ))
	Url4		<- gsub("/$", "", Url4)
	write.table( Url4 ,
		 file = file.path(paste0( Dir[1:(DirValue)], collapse = "/" ), 'Url.txt'), 				 row.names = FALSE, col.names = FALSE, fileEncoding = 'UTF-8')
		
	})[1:3]	
cat( Dir1, " took ", Tid2, "\n")
	Total	<- data.frame( t(Tid2), blogg = Dir[ DirValue ]  )
	Total	<- transform( Total, 
					user.self = round( user.self, 4),
					sys.self  = round( sys.self, 4),
					elapsed = round( elapsed, 4),
					Antal	= NROW( Url4 )
					)
	if( is.null( Total1 ) ){
		Total1	<- Total
		col = TRUE; app <- FALSE
	} else {
		Total1	<- Total
		col = FALSE; app <- TRUE
	}				
	write.table(Total1, file = "time.txt", col.names = col,
					row.names = FALSE, append = app)	
	Sys.sleep(1)
	rm( Url4, Total); gc(reset =TRUE)			
}})[1:3]
	
cat( 'Total time is: ', Tid1)	
	
	
	
	


URL_links	<- data.table( link = unlist( A ), key = 'link')
URL_Link1	<- URL_links[grep( "paypal|twitter|facebook|youtube|linkedin|feed", link, invert = TRUE) , ]
URL_Link2	<- URL_Link1[grep( "http://", link),]
## Clean all the urls from commercial links and alike
Clean_url	<- gsub( "^(http://(www\\.)?)", "", Url2)
Clean_url 	<- gsub( "(\\.(com|ca/blog|html))", "", Clean_url)
Clean_url 	<- do.call("rbind", lapply(strsplit( Clean_url, "/"), 
							function( x ) x[1]))
														
## Grep only links that are used
URL			<- data.frame( )
for( i in 1:length( Clean_url)  ){
	cat( i, "\n")
	Head  		<- gsub("\\s+", "_", BloggName[ i ])
	Url_link	<- Clean_url[ i ]
	Link1		<- URL_Link2[grep( Url_link, link ), ] 
	Link1 		<- ifelse( NROW( Link1 ) == 0 , NA, Link1 ) 
	Link1		<- data.frame( link = unlist( Link1 ))
	URL			<- rbind( URL, data.frame( link = Link1, SajtName = Head ))
}

URL1		<- data.table( URL )
URL1[, link := gsub( "/$", "", link)]
URL1		<- unique( URL1)
write.table( URL1, file = 'sajt.txt', sep = "\t", row.names = FALSE, col.names = FALSE, fileEncoding = 'UTF-8')
#URL1[, sum( link > 0), by = "SajtName"]






getDoParWorkers()
getDoParName()
cl	<- makeCluster(4, type = "SOCK")
registerDoSNOW(cl)
getDoParWorkers()
getDoParName()
GG <- foreach( i = 1:NROW( URL ), .packages = c("RCurl", "XML"), .combine = list,
	 .verbose = TRUE, .export = "webExtract") %dopar% {
	 N <- 	as.character( URL1[ 2, link] )
	 L	<- as.character( URL1[2, SajtName]  ) 
	webExtract( x = N  , name = L)
	}
 
 stopCluster(cl)

for( i in 1:NROW( URL )){
	N	<- as.character( URL[i, SajtName] )
	cat( "Number of rows is ", URL[SajtName == N, sum( links > 0)] , "\t" )
	L	<- as.character(  URL[i, links] )
	cat( "Working on ", N , "\n")
	webExtract( x = L, name =  N )	
}





