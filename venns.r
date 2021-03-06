library(venn); library(tidyverse); library(stringr);

venns <- function (x, snames = "", counts = NULL, ilabels = FALSE, ellipse = FALSE, 
                   zcolor = "bw", opacity = 0.3, size = 15, cexil = 0.6, cexsn = 0.85, 
                   borders = TRUE, ...) 
{
  if (missing(x)) {
    cat("\n")
    stop(simpleError("Argument \"x\" is missing.\n\n"))
  }
  funargs <- unlist(lapply(match.call(), deparse)[-1])
  if (inherits(tryCatch(eval(x), error = function(e) e), "error")) {
    x <- funargs["x"]
  }
  if (is.numeric(x)) {
    if (length(x) > 1) {
      cat("\n")
      stop(simpleError("Argument \"x\" can be a single digit, for up to 7 sets.\n\n"))
    }
  }
  if (!identical(zcolor, "bw") & !identical(zcolor, "style")) {
    zcolor <- unlist(strsplit(gsub("[[:space:]]", "", zcolor), 
                              split = ","))
    testcolor <- tryCatch(col2rgb(zcolor), error = function(e) e)
    if (!is.matrix(testcolor)) {
      cat("\n")
      stop(simpleError("Invalid color(s) in \"zcolor\".\n\n"))
    }
  }
  nofsets <- 0
  if (!identical(snames, "")) {
    nofsets <- length(snames)
  }
  ttqca <- FALSE
  listx <- FALSE
  cts <- NULL
  if (is.numeric(counts) & is.numeric(x)) {
    if (length(counts) == 2^x) {
      cts <- counts
      counts <- TRUE
    }
    else {
      counts <- FALSE
    }
  }
  else {
    counts <- FALSE
  }
  if (inherits(x, "qca") | inherits(x, "tt")) {
    ttqca <- TRUE
    otype <- "input"
    if (inherits(x, "tt")) {
      QCA <- all(which(is.element(c("minmat", "DCC", "options", 
                                    "neg.out", "opts"), names(x))) < 4)
      otype <- "truth table"
      tt <- x$tt
      noflevels <- x$noflevels
    }
    else {
      QCA <- all(which(is.element(c("minmat", "DCC", "options", 
                                    "neg.out", "opts"), names(x$tt))) < 4)
      otype <- "qca"
      oq <- TRUE
      tt <- x$tt$tt
      noflevels <- x$tt$noflevels
    }
    if (!QCA) {
      cat("\n")
      stop(simpleError(sprintf("Please create a proper %s object with package QCA.\n\n", 
                               otype)))
    }
    if (any(noflevels != 2)) {
      cat("\n")
      stop(simpleError("Venn diagrams are not possible for multivalue data.\n\n"))
    }
    if (nofsets == 0) {
      nofsets <- length(snames)
    }
    if (nofsets < 4 | nofsets > 5) {
      ellipse <- FALSE
    }
    ttcolors <- c(`0` = "#ffd885", `1` = "#96bc72", C = "#1c8ac9", 
                  `?` = "#ffffff")
    if (identical(zcolor, "style")) {
      zcolor <- "bw"
    }
    else if (!identical(zcolor, "bw")) {
      if (is.character(zcolor) & length(zcolor) >= 3) {
        ttcolors[c("0", "1", "C")] <- zcolor[1:3]
      }
    }
    individual <- length(opacity) == nrow(tt)
    ints <- read.csv(file.path(system.file("data", package = "venn"), 
                               "ints.csv.gz"))
    openPlot(size)
    if (individual) {
      for (i in seq(nrow(tt))) {
        if (tt$OUT[i] != "?") {
          color <- adjustcolor(ttcolors[tt$OUT[i]], alpha.f = as.numeric(opacity[i]))
          if (i == 1) {
            zeroset <- matrix(c(0, 1000, 1000, 0, 0, 
                                0, 0, 1000, 1000, 0), ncol = 2)
            colnames(zeroset) <- c("x", "y")
            polygons <- rbind(zeroset, rep(NA, 2), getZones(0, 
                                                            nofsets, ellipse)[[1]])
            polygons <- polygons[-nrow(polygons), ]
            polypath(polygons, rule = "evenodd", col = color, 
                     border = NA)
          }
          else {
            polygon(ints[ints$s == nofsets & ints$v == 
                           as.numeric(ellipse) & ints$i == i, c("x", 
                                                                "y")], col = color)
          }
        }
      }
    }
    else {
      for (i in names(ttcolors)[1:3]) {
        zones <- as.numeric(rownames(tt[tt$OUT == i, 
                                        ]))
        if (length(zones) > 0) {
          if (any(zones == 1)) {
            zeroset <- matrix(c(0, 1000, 1000, 0, 0, 
                                0, 0, 1000, 1000, 0), ncol = 2)
            colnames(zeroset) <- c("x", "y")
            polygons <- rbind(zeroset, rep(NA, 2), getZones(0, 
                                                            nofsets, ellipse)[[1]])
            polygons <- polygons[-nrow(polygons), ]
            polypath(polygons, rule = "evenodd", col = ttcolors[i], 
                     border = NA)
            zones <- zones[-1]
          }
          polygon(ints[ints$s == nofsets & ints$v == 
                         as.numeric(ellipse) & ints$i %in% zones, 
                       c("x", "y")], col = ttcolors[i])
        }
      }
    }
    cts <- tt$n
    x <- nofsets
  }
  else if (is.numeric(x)) {
    nofsets <- x
    if (!identical(snames, "")) {
      if (length(snames) != nofsets) {
        cat("\n")
        stop(simpleError("Number of sets not equal with the number of set names.\n\n"))
      }
    }
  }
  else if (is.character(x)) {
    if (any(grepl("\\$solution", funargs["x"]))) {
      obj <- get(unlist(strsplit(funargs["x"], split = "[$]"))[1])
      snames <- obj$tt$options$conditions
      nofsets <- length(snames)
    }
    x <- splitstr(x)
    if (all(grepl("[A-Za-z]", x))) {
      if (identical(snames, "")) {
        y <- translate2(paste(x, collapse = "+"), snames)
        snames <- colnames(x)
        nofsets <- length(snames)
      }
      x <- lapply(x, function(x) {
        return(paste(apply(translate2(x, snames), 1, 
                           function(x) {
                             x[x < 0] <- "-"
                             paste(x, collapse = "")
                           }), collapse = "+"))
      })
    }
    if (!is.list(x)) {
      if (!all(gsub("0|1|-|\\+", "", x) == "")) {
        cat("\n")
        stop(simpleError("Invalid codes in the rule(s).\n\n"))
      }
      if (nofsets == 0) {
        nofsets <- unique(nchar(splitstr(x, split = "\\+")))
      }
      x <- as.list(x)
    }
  }
  else if (is.data.frame(x)) {
    if (!is.null(names(x))) {
      if (all(names(x) != "")) {
        snames <- names(x)
      }
    }
    if (!all(apply(x, 1, function(l) all(l %in% 0:1)))) {
      cat("\n")
      stop(simpleError("As a dataframe, \"x\" can only contain values 0 and 1.\n\n"))
    }
    if (nofsets == 0) {
      nofsets <- length(x)
    }
    cts <- apply(sapply(rev(seq(nofsets)), function(x) {
      rep.int(c(sapply(0:1, function(y) rep.int(y, 2^(x - 
                                                        1)))), 2^nofsets/2^x)
    }), 1, function(l1) {
      sum(apply(x, 1, function(l2) {
        all(l1 == l2)
      }))
    })
    counts <- TRUE
    x <- nofsets
  }
  else if (is.list(x)) {
    if (any(grepl("\\$solution", funargs["x"]))) {
      obj <- get(unlist(strsplit(funargs["x"], split = "[$]"))[1])
      snames <- obj$tt$options$conditions
      nofsets <- length(snames)
      x <- translate2(paste(unlist(x), collapse = " + "), 
                      snames)
      x <- as.list(apply(x, 1, function(y) {
        y[y < 0] <- "-"
        paste(y, collapse = "")
      }))
    }
    else {
      listx <- TRUE
      if (length(x) > 7) {
        x <- x[seq(7)]
      }
      if (!is.null(names(x))) {
        if (all(names(x) != "")) {
          snames <- names(x)
        }
      }
      if (identical(snames, "")) {
        snames <- LETTERS[seq(length(x))]
      }
      if (nofsets == 0) {
        nofsets <- length(x)
      }
      tt <- sapply(rev(seq(nofsets)), function(x) {
        rep.int(c(sapply(0:1, function(y) rep.int(y, 
                                                  2^(x - 1)))), 2^nofsets/2^x)
      })
      colnames(tt) <- snames
      intersections <- apply(tt, 1, function(y) {
        setdiff(Reduce(intersect, x[y == 1]), unlist(x[y == 
                                                         0]))
      })
      names(intersections) <- apply(tt, 1, function(x) paste(snames[x == 
                                                                      1], collapse = ":"))
      cts <- unlist(lapply(intersections, length))
      intersections <- intersections[cts > 0]
      tt <- as.data.frame(cbind(tt, counts = cts))
      attr(tt, "intersections") <- intersections
      counts <- TRUE
      x <- nofsets
    }
  }
  else {
    cat("\n")
    stop(simpleError("Unrecognised argument \"x\".\n\n"))
  }
  if (nofsets > 7) {
    cat("\n")
    stop(simpleError("Venn diagrams can be drawn up to 7 sets.\n\n"))
  }
  if (identical(snames, "")) {
    snames <- LETTERS[seq(nofsets)]
  }
  else {
    if (length(snames) != nofsets) {
      cat("\n")
      stop(simpleError("Length of set names does not match the number of sets.\n\n"))
    }
  }
  if (!is.element("cexil", names(funargs))) {
    cexil <- cexil - ifelse(nofsets > 5, 0.1, 0) - ifelse(nofsets > 
                                                            6, 0.05, 0)
  }
  if (!ttqca) {
    openPlot(size)
  }
  plotRules(x, zcolor, ellipse, opacity, allborders = borders, 
            ... = ...)
  scoords <- data.frame(s = c(1, rep(2, 2), rep(3, 3), rep(4, 
                                                           4), rep(5, 10), rep(6, 6), rep(7, 7), rep(4, 4)), v = c(rep(0, 
                                                                                                                       1 + 2 + 3), rep(1, 4), rep(0:1, each = 5), rep(0, 6 + 
                                                                                                                                                                        7), rep(0, 4)), x = c(500, 250, 750, 100, 500, 900, 88, 
                                                                                                                                                                                              263, 713, 888, 80, 535, 900, 700, 120, 88, 533, 850, 
                                                                                                                                                                                              750, 163, 100, 500, 910, 925, 550, 100, 220, 685, 935, 
                                                                                                                                                                                              935, 600, 155, 50, 85, 220, 780, 915), y = c(780, 780, 
                                                                                                                                                                                                                                           780, 560, 910, 560, 663, 850, 850, 663, 800, 960, 700, 
                                                                                                                                                                                                                                           50, 120, 750, 963, 688, 40, 88, 860, 975, 775, 165, 30, 
                                                                                                                                                                                                                                           140, 955, 980, 780, 200, 15, 120, 690, 670, 850, 850, 
                                                                                                                                                                                                                                           670))
  if (ilabels | counts & !is.null(cts)) {
    icoords <- read.csv(file.path(system.file("data", package = "venn"), 
                                  "icoords.csv.gz"))
    ilabels <- icoords$l[icoords$s == nofsets & icoords$v == 
                           as.numeric(ellipse)]
    if (counts) {
      cts[cts == 0] <- ""
      ilabels <- cts
    }
    text(icoords[icoords$s == nofsets & icoords$v == as.numeric(ellipse), 
                 c("x", "y")], labels = ilabels, cex = cexil)
  }
  text(scoords[scoords$s == nofsets & scoords$v == as.numeric(ellipse), 
               c("x", "y")], labels = snames, cex = cexsn)
  if (ttqca) {
    points(seq(10, 340, length.out = 4), rep(-25, 4), pch = 22, 
           bg = ttcolors, cex = 1.75)
    text(seq(40, 370, length.out = 4), rep(-26, 4), names(ttcolors), 
         cex = 0.85)
  }
  if (listx) {
    return(invisible(tt))
  }
}
