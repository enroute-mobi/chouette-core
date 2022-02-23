# Disable WebMock on :
# - codacy requests
# - google fonts for mailers
# - Datadog trace requests
WebMock.disable_net_connect!(allow: ['fonts.googleapis.com', 'api.codacy.com', '127.0.0.1:8126', 'http://mock.api.tomtom.com'])
