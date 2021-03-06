# :vim set ff=R

## record default layout so that we can restore later
default.layout <- flog.layout()

context("format string")
test_that("Embedded format string", {
  flog.threshold(INFO)
  raw <- capture.output(flog.info("This is a %s message", "log"))
  #cat("\n[test.default] Raw:",raw,"\n")
  expect_that(length(grep('INFO', raw)) > 0, is_true())
  expect_that(length(grep('log message', raw)) > 0, is_true())
})

test_that("layout.simple.parallel layout", {
  flog.threshold(INFO)
  flog.layout(layout.simple.parallel)
  raw <- capture.output(flog.info("log message"))
  expect_that(length(paste0('INFO [[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} ', Sys.getpid(), '] log message') ==  raw) > 0, is_true())
  expect_that(length(grep('log message', raw)) > 0, is_true())
})

test_that("~p token", {
  flog.threshold(INFO)
  flog.layout(layout.format('xxx[~l ~p]xxx'))
  raw <- capture.output(flog.info("log message"))
  expect_that(paste0('xxx[INFO ',Sys.getpid(),']xxx') == raw, is_true())
  expect_that(length(grep('log message', raw)) == 0, is_true())
})

test_that("~i token (logger name)", {
  flog.threshold(INFO)
  flog.layout(layout.format('<~i> ~m'))
  # with no logger name 
  # (perhaps due to the behavior of flog.namespace for nested function call, 
  #  logger name becomes "base" instead of "futile.logger" 
  #  when no name is given.  this test is currently disabled)
  #out <- flog.info("log message")
  #out <- sub('[[:space:]]+$', '', out)  # remove line break at end
  #expect_equal(out, '<ROOT> log message')

  # with logger name
  out <- capture.output(flog.info("log message", name='mylogger'))
  expect_equal(out, '<mylogger> log message')
})

test_that("Custom layout dereferences level field", {
  flog.threshold(INFO)
  flog.layout(layout.format('xxx[~l]xxx'))
  raw <- capture.output(flog.info("log message"))
  expect_that('xxx[INFO]xxx' == raw, is_true())
  expect_that(length(grep('log message', raw)) == 0, is_true())
})

context("null values")
flog.layout(default.layout)
test_that("Raw null value is printed", {
  raw <- capture.output(flog.info('xxx[%s]xxx', NULL))
  expect_that(length(grep('xxx[NULL]xxx', raw, fixed=TRUE)) == 1, is_true())
})

test_that("Single null value is printed", {
  opt <- list()
  raw <- capture.output(flog.info('xxx[%s]xxx', opt$noexist))
  expect_that(length(grep('xxx[NULL]xxx', raw, fixed=TRUE)) == 1, is_true())
})

test_that("Null is printed amongst variables", {
  opt <- list()
  raw <- capture.output(flog.info('aaa[%s]aaa xxx[%s]xxx', 3, opt$noexist))
  expect_that(length(grep('aaa[3]aaa', raw, fixed=TRUE)) == 1, is_true())
  expect_that(length(grep('xxx[NULL]xxx', raw, fixed=TRUE)) == 1, is_true())
})

context("sprintf arguments")
test_that("no extra arguments are passed", {
  expect_true(grepl('foobar$', capture.output(flog.info('foobar'))))
  expect_true(grepl('foobar %s$', capture.output(flog.info('foobar %s'))))
  expect_true(grepl('10%$', capture.output(flog.info('10%'))))
})
test_that("some extra arguments are passed", {
  expect_true(grepl('foobar$', capture.output(flog.info('foobar', pi))))
  expect_true(grepl(
    'foobar foo$',
    capture.output(flog.info('foobar %s', 'foo'))))
  expect_true(grepl('100$', capture.output(flog.info('10%d', 0))))
  expect_true(
    grepl('foo and bar equals to foobar',
          capture.output(
            flog.info('%s and %s equals to %s', 'foo', 'bar', 'foobar'))))
})

context("Function name and namespace detection")
test_that("Function name detection inside nested functions", {
    flog.layout(layout.format("[~f] ~m"))
    a <- function() { flog.info("inside A") }
    b <- function() { a() }
    d <- function() { b() }
    e <- function() { d() }
    expect_equal('[a] inside A', capture.output(e()))
})

drop_log_prefix <- function(msg) {
    sub('[A-Z]* \\[.*\\] ', '', msg)
}

context("glue layout")
flog.layout(layout.glue)
test_that("glue features work", {
  expect_equal(drop_log_prefix(capture.output(flog.info('foobar'))),
               'foobar')
  expect_equal(drop_log_prefix(capture.output(flog.info('{a}{b}', a = 'foo', b = 'bar'))),
               'foobar')
  expect_equal(drop_log_prefix(capture.output(flog.info('foo{b}', b = 'bar'))),
               'foobar')
  b <- 'bar'
  expect_equal(drop_log_prefix(capture.output(flog.info('foo{b}'))),
               'foobar')
  rm(b)
  expect_equal(drop_log_prefix(capture.output(flog.info('foo', 'bar'))),
               'foobar')
})

## back to the default layout
invisible(flog.layout(default.layout))
