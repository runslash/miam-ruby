-- example HTTP POST script which demonstrates setting the
-- HTTP method, body, and adding a header

wrk.method = "POST"
wrk.body   = '{"operation_name":"iam:DescribeUser","auth_token":"MIAM-AK-V1 credentials=AKRLDNFSQMWK5JN4FHGC3Q; date=1587420316; signature=41f25a0c0be60980a863bcd08d054d45d76db9d381513aa540a4ae5265a4a50e","auth_headers":{"x":"x"},"auth_body_signature":"bf21a9e8fbc5a3846fb05b4fa0859e0917b2202f"}'
wrk.headers["Content-Type"] = "application/json"
