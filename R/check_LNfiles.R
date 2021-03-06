#' Check LexisNexis TXT files
#'
#' Read a LexisNexis TXT file and check consistency.
#' @param x Name or names of LexisNexis TXT file to be converted.
#' @param encoding Encoding to be assumed for input files. Defaults to UTF-8 (the LexisNexis standard value).
#' @param verbose A logical flag indicating whether information should be printed to the screen.
#' @param start_keyword/end_keyword/length_keyword see \link[LexisNexisTools]{read_LN}
#' @keywords LexisNexis
#' @details Can check consistency of LexisNexis txt files. read_LN needs at least Beginning, End and length in each article to work
#' @author Johannes B. Gruber
#' @export
#' @examples 

 
check_LNfiles <- function(x, encoding = "UTF-8", 
                          start_keyword = "\\d+ of \\d+ DOCUMENTS$| Dokument \\d+ von \\d+$",
                          end_keyword = "^LANGUAGE: |^SPRACHE: ",
                          length_keyword = "^LENGTH: |^LÄNGE: ",
                          verbose = TRUE){
  ###' Track the time
  if(verbose){start.time <- Sys.time(); cat("Checking LN files...\n")}
  
  ### read in file
  out <- lapply(x, function(i){
    if(verbose){cat("\r\tChecking file:",i,"...\t\t",sep="")}
    articles.v <- stringi::stri_read_lines(i, encoding = encoding)
    Beginnings <- grep(start_keyword, articles.v)
    Ends <- grep(end_keyword, articles.v)
    lengths <- grep(length_keyword, articles.v)
    ### Debug lengths
    # one line before and after length are always empty
    lengths <-  lengths[!(articles.v[lengths+1]!=""|articles.v[lengths-1]!="")]
    #same for Ends
    Ends <-  Ends[!(articles.v[Ends+1]!=""|articles.v[Ends-1]!="")]
    # does language appear in metadata before article
    for (n in 1:min(c(length(Beginnings), length(Ends), length(lengths)))){
      if(Beginnings[n] > Ends[n] & Ends[n] < lengths[n]){Ends <- Ends[-n]}
      }
    # Note: In some rare cases, this will delete articles that do not contain length for other reasons
    if(length(which(Ends[1:(length(lengths))]<lengths))>0) {
      for (n in 1:(length(Beginnings)-length(lengths))){
        # Which Ends are smaller than length? in those cases length is absent and the article gets neglected.
        empty.articles <- which(Ends[1:(length(lengths))]<lengths)
        if(length(empty.articles) > 0){
          Beginnings <-Beginnings[-(empty.articles[1])]
          Ends<-Ends[-(empty.articles[1])]
        }else{
          if(max(lengths)<max(Beginnings)){
            Beginnings <- Beginnings[-which.max(Beginnings)]
            Ends <- Ends[-which.max(Ends)]
          }
        }
      }
    }
    
    # range
    range.v <- articles.v[grep("^Download Request|^Ausgabeauftrag:", articles.v)]
    range.v <- unlist(strsplit(range.v, "-"))
    range.v <- gsub("[[:alpha:]]|[[:punct:]]|\\s+", "", range.v)
    range.v <- as.numeric(range.v[2])-as.numeric(range.v[1])+1
    out <- data.frame(file = i,
                      Beginnings = length(Beginnings),
                      Ends = length(Ends),
                      Lengths = length(lengths),
                      range = range.v,
                      Test1 = length(Beginnings) == length(Ends),
                      Test2 = length(Beginnings) == length(lengths),
                      Test3 = length(Beginnings) == range.v,
                      stringsAsFactors = FALSE)
    out
  })
  out <- data.table::rbindlist(out)
  
  if(verbose){cat("\nElapsed time: ", format((Sys.time()-start.time), digits = 2, nsmall = 2),"\n", sep = "")}
  out
}
