###############################################################################
#
#                                 NOTICE:
#  THIS PROGRAM CONSISTS OF TRADE SECRECTS THAT ARE THE PROPERTY OF
#  Advanced Products Ltd. THE CONTENTS MAY NOT BE USED OR DISCLOSED
#  WITHOUT THE EXPRESS WRITTEN PERMISSION OF THE OWNER.
#
#               COPYRIGHT Advanced Products Ltd 2016-2019
#
###############################################################################

source("api/qp_api_server.R")
source("api/qp_model.R")
source("api/qp_model_run.R")

model_run_function<-function(model_run)
{
  # set the parameters
  qp_model_run_set_parameter_value(model_run, 'demo/put_or_call', 'call')
  
  # set update timestamp
  update_timestamp<-as.numeric(Sys.time()) * 1000
  
  # get input
  input<-qp_model_run_get_input(model_run)
  output<-qp_model_run_get_output(model_run)
  
  # start reading messages
  number_of_instruments<-0
  should_read<-TRUE
  while(TRUE == should_read)
  {
    message<-qp_reader_read_message(input, 1000)
    if(TRUE == is.null(message))
    {
      should_read<-FALSE
      break
    }
    print(message)
    
    # if we are a call
    if("call" == message$option_type)
    {
      output_message<-list(symbol = message$value.instrument_name, expiry=message$value.expiration_timestamp, strike = message$value.strike, update_time = update_timestamp)
      
      # write data out
      qp_writer_write_message(output, output_message)
      
      # bump the count
      number_of_instruments = number_of_instruments + 1
    }
  }
  
  # set metrics
  qp_model_run_set_metric_value(model_run,'demo/number_of_instruments', number_of_instruments)


  return (model_run)
  
}

qp_initialise()
server<-qp_server_create('localhost', port=8080)
new_model<-qp_model_load(server, "demo", "filter_instruments")

metrics<-qp_model_get_metrics(new_model)
parameters<-qp_model_get_parameters(new_model)

model_run_name<-paste("R api demo ", as.POSIXlt(Sys.time()), sep="", collapse="")
model_run<-qp_model_new_run(new_model, model_run_name, model_run_function, offset=1)
