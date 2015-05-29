local ffi = require "ffi"
local IS_WINDOWS = (ffi.os: lower() == 'windows') or
(package.config: sub(1,1) == '\\')

local function orequire(...)
	local err = ""
	for _, name in ipairs{ ...}  do

		local ok, mod = pcall(require, name)
		if ok then
 return mod, name end
		err = err .. "\n" .. mod
	end
	error(err)
end

local function oload(t)
	local err = ""
	for _, name in ipairs(t) do

		local ok, mod = pcall(ffi.load, name)
		if ok then
 return mod, name end
		err = err .. "\n" .. mod
	end
	error(err)
end

local function IF(cond, true_v, false_v)
	if cond then
 return true_v end
	return false_v
end

local bit = orequire("bit32", "bit")

local zlibs if IS_WINDOWS then

	zlibs = { 
	"zmq", "libzmq",
	"zmq4", "libzmq4",
	"zmq3", "libzmq3",
	} 
else
	zlibs = { 
	"zmq", "libzmq",
	"zmq.so.4", "libzmq.so.4",
	"zmq.so.3", "libzmq.so.3",
	"/usr/local/lib/libzmq.so",
	"/usr/local/lib/libzmq.so.4",
	"/usr/local/lib/libzmq.so.3",
	} 
end

local ok, libzmq3 = pcall( oload, zlibs )
if not ok then

	if pcall( require, "lzmq" ) then
 -- jus to load libzmq3
		libzmq3 = oload( zlibs )
	else error(libzmq3) end
end

local aint_t = ffi.typeof("int[1]")
local aint16_t = ffi.typeof("int16_t[1]")
local auint16_t = ffi.typeof("uint16_t[1]")
local aint32_t = ffi.typeof("int32_t[1]")
local auint32_t = ffi.typeof("uint32_t[1]")
local aint64_t = ffi.typeof("int64_t[1]")
local auint64_t = ffi.typeof("uint64_t[1]")
local asize_t = ffi.typeof("size_t[1]")
local vla_char_t = ffi.typeof("char[?]")
local pvoid_t = ffi.typeof("void* ")
local pchar_t = ffi.typeof("char* ")
local uintptr_t = ffi.typeof("uintptr_t")
local NULL = ffi.cast(pvoid_t, 0)
local int16_size = ffi.sizeof("int16_t")
local int32_size = ffi.sizeof("int32_t")
local ptr_size = ffi.sizeof(pvoid_t)
local fd_t, afd_t
if IS_WINDOWS and ffi.arch == 'x64' then

	fd_t, afd_t = "uint64_t", auint64_t
else
	fd_t, afd_t = "int", aint_t
end

ffi.cdef[[
void zmq_version (int * major, int * minor, int * patch);
]]

local _M = { } 

-- zmq_version
do


function _M.zmq_version()
	local major, minor, patch = ffi.new(aint_t, 0), ffi.new(aint_t, 0), ffi.new(aint_t, 0)
	libzmq3.zmq_version(major, minor, patch)
	return major[0], minor[0], patch[0]
end

end

local ZMQ_VERSION_MAJOR, ZMQ_VERSION_MINOR, ZMQ_VERSION_PATCH = _M.zmq_version()
assert(
((ZMQ_VERSION_MAJOR == 3) and (ZMQ_VERSION_MINOR >= 2)) or (ZMQ_VERSION_MAJOR == 4),
"Unsupported ZMQ version:  " .. ZMQ_VERSION_MAJOR .. "." .. ZMQ_VERSION_MINOR .. "." .. ZMQ_VERSION_PATCH
)

-- >=
local is_zmq_ge = function (major, minor, patch)
if ZMQ_VERSION_MAJOR < major then
 return false end
if ZMQ_VERSION_MAJOR > major then
 return true end
if ZMQ_VERSION_MINOR < minor then
 return false end
if ZMQ_VERSION_MINOR > minor then
 return true end
if ZMQ_VERSION_PATCH < patch then
 return false end
return true
end

if is_zmq_ge(4, 1, 0) then

ffi.cdef[[
typedef struct zmq_msg_t { unsigned char _ [40];}  zmq_msg_t;
]]
else
ffi.cdef[[
typedef struct zmq_msg_t { unsigned char _ [32];}  zmq_msg_t;
]]
end

ffi.cdef[[
int zmq_errno (void);
const char * zmq_strerror (int errnum);

void * zmq_ctx_new (void);
int zmq_ctx_term (void * context);
int zmq_ctx_destroy (void * context);
int zmq_ctx_shutdown (void * context);
int zmq_ctx_set (void * context, int option, int optval);
int zmq_ctx_get (void * context, int option);

void * zmq_socket (void * , int type);
int zmq_close (void * s);
int zmq_setsockopt (void * s, int option, const void * optval, size_t optvallen); 
int zmq_getsockopt (void * s, int option, void * optval, size_t * optvallen);
int zmq_bind (void * s, const char * addr);
int zmq_connect (void * s, const char * addr);
int zmq_unbind (void * s, const char * addr);
int zmq_disconnect (void * s, const char * addr);
int zmq_send (void * s, const void * buf, size_t len, int flags);
int zmq_recv (void * s, void * buf, size_t len, int flags);
int zmq_socket_monitor (void * s, const char * addr, int events);
int zmq_sendmsg (void * s, zmq_msg_t * msg, int flags);
int zmq_recvmsg (void * s, zmq_msg_t * msg, int flags);

int zmq_msg_init (zmq_msg_t * msg);
int zmq_msg_init_size (zmq_msg_t * msg, size_t size);
void * zmq_msg_data (zmq_msg_t * msg);
size_t zmq_msg_size (zmq_msg_t * msg);
int zmq_msg_close (zmq_msg_t * msg);
int zmq_msg_send (zmq_msg_t * msg, void * s, int flags);
int zmq_msg_recv (zmq_msg_t * msg, void * s, int flags);
int zmq_msg_move (zmq_msg_t * dest, zmq_msg_t * src);
int zmq_msg_copy (zmq_msg_t * dest, zmq_msg_t * src);

int zmq_msg_more (zmq_msg_t * msg);
int zmq_msg_get (zmq_msg_t * msg, int option);
int zmq_msg_set (zmq_msg_t * msg, int option, int optval);
]]

ffi.cdef([[
typedef struct { 
void * socket;
]] .. IF(IS_WINDOWS, "uint32_t", "int") .. [[ fd;
short events;
short revents;
}  zmq_pollitem_t;

int zmq_poll (zmq_pollitem_t * items, int nitems, long timeout);
]])

ffi.cdef[[
int zmq_proxy (void * frontend, void * backend, void * capture);
int zmq_device (int type, void * frontend, void * backend);
int zmq_proxy_steerable (void * frontend, void * backend, void * capture, void * control);
]]

ffi.cdef[[
char * zmq_z85_encode (char * dest, const char * data, size_t size);
char * zmq_z85_decode (char * dest, const char * string);
int zmq_curve_keypair (char * z85_public_key, char * z85_secret_key);
]]

ffi.cdef[[
void * zmq_stopwatch_start (void);
unsigned long zmq_stopwatch_stop (void * watch_);
]]

local zmq_msg_t = ffi.typeof("zmq_msg_t")
local vla_pollitem_t = ffi.typeof("zmq_pollitem_t[?]")
local zmq_pollitem_t = ffi.typeof("zmq_pollitem_t")
local pollitem_size = ffi.sizeof(zmq_pollitem_t)

local function ptrtoint(ptr)
return tonumber(ffi.cast(uintptr_t, ptr))
end

local function inttoptr(val)
return ffi.cast(pvoid_t, ffi.cast(uintptr_t, val))
end

local ptrtostr, strtoptr do

local void_array = ffi.new("void* [1]")
local char_ptr = ffi.cast(pchar_t, void_array)

ptrtostr = function (ptr)
void_array[0] = ptr
return ffi.string(char_ptr, ptr_size)
end

strtoptr = function (str)
if type(str) == 'string' then

	assert(#str == ptr_size)
	ffi.copy(char_ptr, str, ptr_size)
	return void_array[0]
end

-- we can support also lightuserdata
assert(type(str) == 'userdata')
return ffi.cast(pvoid_t, str)
end

end

local serialize_ptr, deserialize_ptr = ptrtostr, strtoptr

local function pget(lib, elem)
local ok, err = pcall(function()
local m = lib[elem]
if nil ~= m then
 return m end
error("not found")
end)
if ok then
 return err end
return nil, err
end

-- zmq_errno, zmq_strerror, zmq_poll, zmq_device, zmq_proxy
do


function _M.zmq_errno()
return libzmq3.zmq_errno()
end

function _M.zmq_strerror(errnum)
local str = libzmq3.zmq_strerror (errnum);
return ffi.string(str)
end

function _M.zmq_poll(items, nitems, timeout)
return libzmq3.zmq_poll(items, nitems, timeout)
end

function _M.zmq_device(dtype, frontend, backend)
return libzmq3.zmq_device(dtype, frontend, backend)
end

function _M.zmq_proxy(frontend, backend, capture)
return libzmq3.zmq_proxy(frontend, backend, capture)
end

if pget(libzmq3, "zmq_proxy_steerable") then


function _M.zmq_proxy_steerable(frontend, backend, capture, control)
return libzmq3.zmq_proxy_steerable(frontend, backend, capture, control)
end

end

end

-- zmq_ctx_new, zmq_ctx_term, zmq_ctx_get, zmq_ctx_set
do


function _M.zmq_ctx_new()
local ctx = libzmq3.zmq_ctx_new()
ffi.gc(ctx, _M.zmq_ctx_term)
return ctx
end

if pget(libzmq3, "zmq_ctx_shutdown") then

function _M.zmq_ctx_shutdown(ctx)
return libzmq3.zmq_ctx_shutdown(ctx)
end
end

if pget(libzmq3, "zmq_ctx_term") then

function _M.zmq_ctx_term(ctx)
return libzmq3.zmq_ctx_term(ffi.gc(ctx, nil))
end
else
function _M.zmq_ctx_term(ctx)
libzmq3.zmq_ctx_destroy(ffi.gc(ctx, nil))
end
end

function _M.zmq_ctx_get(ctx, option)
return libzmq3.zmq_ctx_get(ctx, option)
end

function _M.zmq_ctx_set(ctx, option, value)
return libzmq3.zmq_ctx_set(ctx, option, value)
end

end

-- zmq_send, zmq_recv, zmq_sendmsg, zmq_recvmsg,
-- zmq_socket, zmq_close, zmq_connect, zmq_bind, zmq_unbind, zmq_disconnect,
-- zmq_skt_setopt_int, zmq_skt_setopt_i64, zmq_skt_setopt_u64, zmq_skt_setopt_str,
-- zmq_skt_getopt_int, zmq_skt_getopt_i64, zmq_skt_getopt_u64, zmq_skt_getopt_str
-- zmq_socket_monitor
do


function _M.zmq_socket(ctx, stype)
local skt = libzmq3.zmq_socket(ctx, stype)
if NULL == skt then
 return nil end
ffi.gc(skt, _M.zmq_close)
return skt
end

function _M.zmq_close(skt)
return libzmq3.zmq_close(ffi.gc(skt,nil))
end

local function gen_setopt_int(t, ct)
return function (skt, option, optval) 
local size = ffi.sizeof(t)
local val = ffi.new(ct, optval)
return libzmq3.zmq_setsockopt(skt, option, val, size)
end
end

local function gen_getopt_int(t, ct)
return function (skt, option) 
local size = ffi.new(asize_t, ffi.sizeof(t))
local val = ffi.new(ct, 0)
if -1 ~= libzmq3.zmq_getsockopt(skt, option, val, size) then

return val[0]
end
return
end
end

_M.zmq_skt_setopt_int = gen_setopt_int("int", aint_t )
_M.zmq_skt_setopt_i64 = gen_setopt_int("int64_t", aint64_t )
_M.zmq_skt_setopt_u64 = gen_setopt_int("uint64_t", auint64_t)

function _M.zmq_skt_setopt_str(skt, option, optval)
return libzmq3.zmq_setsockopt(skt, option, optval, #optval)
end

_M.zmq_skt_getopt_int = gen_getopt_int("int", aint_t )
_M.zmq_skt_getopt_fdt = gen_getopt_int(fd_t, afd_t )
_M.zmq_skt_getopt_i64 = gen_getopt_int("int64_t", aint64_t )
_M.zmq_skt_getopt_u64 = gen_getopt_int("uint64_t", auint64_t)

function _M.zmq_skt_getopt_str(skt, option)
local len = 255
local val = ffi.new(vla_char_t, len)
local size = ffi.new(asize_t, len)
if -1 ~= libzmq3.zmq_getsockopt(skt, option, val, size) then

if size[0] > 0 then

return ffi.string(val, size[0] - 1)
end
return ""
end
return
end

function _M.zmq_connect(skt, addr)
return libzmq3.zmq_connect(skt, addr)
end

function _M.zmq_bind(skt, addr)
return libzmq3.zmq_bind(skt, addr)
end

function _M.zmq_unbind(skt, addr)
return libzmq3.zmq_unbind(skt, addr)
end

function _M.zmq_disconnect(skt, addr)
return libzmq3.zmq_disconnect(skt, addr)
end

function _M.zmq_send(skt, data, flags)
return libzmq3.zmq_send(skt, data, #data, flags or 0)
end

function _M.zmq_recv(skt, len, flags)
local buf = ffi.new(vla_char_t, len)
local flen = libzmq3.zmq_recv(skt, buf, len, flags or 0)
if flen < 0 then
 return end
if len > flen then
 len = flen end
return ffi.string(buf, len), flen
end

function _M.zmq_sendmsg(skt, msg, flags) 
return libzmq3.zmq_sendmsg(skt, msg, flags)
end

function _M.zmq_recvmsg(skt, msg, flags)
return libzmq3.zmq_recvmsg(skt, msg, flags)
end

function _M.zmq_socket_monitor(skt, addr, events)
return libzmq3.zmq_socket_monitor(skt, addr, events)
end

end

-- zmq_msg_init, zmq_msg_init_size, zmq_msg_data, zmq_msg_size, zmq_msg_get, 
-- zmq_msg_set, zmq_msg_move, zmq_msg_copy, zmq_msg_set_data, zmq_msg_get_data, 
-- zmq_msg_init_string, zmq_msg_recv, zmq_msg_send, zmq_msg_more
do
 -- message

function _M.zmq_msg_init(msg)
msg = msg or ffi.new(zmq_msg_t)
if 0 == libzmq3.zmq_msg_init(msg) then

return msg
end
return
end

function _M.zmq_msg_init_size(msg, len)
if not len then
 msg, len = nil, msg end
local msg = msg or ffi.new(zmq_msg_t)
if 0 == libzmq3.zmq_msg_init_size(msg, len) then

return msg
end
return
end

function _M.zmq_msg_data(msg, pos)
local ptr = libzmq3.zmq_msg_data(msg)
pos = pos or 0
if pos == 0 then
 return ptr end
ptr = ffi.cast(pchar_t, ptr) +  pos
return ffi.cast(pvoid_t, ptr)
end

function _M.zmq_msg_size(msg)
return libzmq3.zmq_msg_size(msg)
end

function _M.zmq_msg_close(msg)
libzmq3.zmq_msg_close(msg)
end

local function get_msg_copy(copy)
return function (dest, src)
local new = false
if not src then
 
new, src = true, dest
dest = _M.zmq_msg_init()
if not dest then
 return end
end
local ret = copy(dest, src)
if ret == -1 then

if new then
 _M.zmq_msg_close(dest) end
return
end
return dest
end
end

_M.zmq_msg_move = get_msg_copy(libzmq3.zmq_msg_move)
_M.zmq_msg_copy = get_msg_copy(libzmq3.zmq_msg_copy)

function _M.zmq_msg_set_data(msg, str)
ffi.copy(_M.zmq_msg_data(msg), str)
end

function _M.zmq_msg_get_data(msg)
return ffi.string(_M.zmq_msg_data(msg), _M.zmq_msg_size(msg))
end

function _M.zmq_msg_init_string(str)
local msg = _M.zmq_msg_init_size(#str)
_M.zmq_msg_set_data(msg, str)
return msg
end

function _M.zmq_msg_recv(msg, skt, flags)
return libzmq3.zmq_msg_recv(msg, skt, flags or 0)
end

function _M.zmq_msg_send(msg, skt, flags)
return libzmq3.zmq_msg_send(msg, skt, flags or 0)
end

function _M.zmq_msg_more(msg)
return libzmq3.zmq_msg_more(msg)
end

function _M.zmq_msg_get(msg, option)
return libzmq3.zmq_msg_get(msg, option)
end

function _M.zmq_msg_set(msg, option, optval)
return libzmq3.zmq_msg_set(msg, option, optval)
end

end

-- zmq_z85_encode, zmq_z85_decode
if pget(libzmq3, "zmq_z85_encode") then


-- we alloc buffers for CURVE encoded key size
local TMP_BUF_SIZE = 41

local function alloc_z85_buff(len)
if len <= TMP_BUF_SIZE then

if not tmp_buf then

tmp_buf = ffi.new(vla_char_t, TMP_BUF_SIZE)
end
return tmp_buf
end
return ffi.new(vla_char_t, len)
end

function _M.zmq_z85_encode(data)
local len = math.floor(#data *  1.25 +  1.0001)
local buf = alloc_z85_buff(len)
local ret = libzmq3.zmq_z85_encode(buf, data, #data)
if ret == NULL then
 error("size of the block must be divisible by 4") end
return ffi.string(buf, len - 1)
end

function _M.zmq_z85_decode(data)
local len = math.floor(#data *  0.8 +  0.0001)
local buf = alloc_z85_buff(len)
local ret = libzmq3.zmq_z85_decode(buf, data)
if ret == NULL then
 error("size of the block must be divisible by 5") end
return ffi.string(buf, len)
end

end

-- zmq_curve_keypair
if pget(libzmq3, "zmq_curve_keypair") then


function _M.zmq_curve_keypair(as_binary)
local public_key = ffi.new(vla_char_t, 41)
local secret_key = ffi.new(vla_char_t, 41)
local rc = libzmq3.zmq_curve_keypair(public_key, secret_key)
if ret == -1 then
 return -1 end
if not as_binary then

return ffi.string(public_key, 40), ffi.string(secret_key, 40)
end
local public_key_bin = ffi.new(vla_char_t, 32)
local secret_key_bin = ffi.new(vla_char_t, 32)

libzmq3.zmq_z85_decode(public_key_bin, public_key)
libzmq3.zmq_z85_decode(secret_key_bin, secret_key)

return ffi.string(public_key_bin, 32), ffi.string(secret_key_bin, 32)
end

end

-- zmq_recv_event
do


local msg = ffi.new(zmq_msg_t)

if ZMQ_VERSION_MAJOR == 3 then

ffi.cdef([[
typedef struct { 
int event;
union { 
struct { 
char * addr;
int fd;
}  connected;
struct { 
char * addr;
int err;
}  connect_delayed;
struct { 
char * addr;
int interval;
}  connect_retried;
struct { 
char * addr;
int fd;
}  listening;
struct { 
char * addr;
int err;
}  bind_failed;
struct { 
char * addr;
int fd;
}  accepted;
struct { 
char * addr;
int err;
}  accept_failed;
struct { 
char * addr;
int fd;
}  closed;
struct { 
char * addr;
int err;
}  close_failed;
struct { 
char * addr;
int fd;
}  disconnected;
}  data;
}  zmq_event_t;
]])
local zmq_event_t = ffi.typeof("zmq_event_t")
local event_size = ffi.sizeof(zmq_event_t)
local event = ffi.new(zmq_event_t)

function _M.zmq_recv_event(skt, flags)
local msg = _M.zmq_msg_init(msg)
if not msg then
 return end

local ret = _M.zmq_msg_recv(msg, skt, flags)
if ret == -1 then

_M.zmq_msg_close(msg)
return
end

assert(_M.zmq_msg_size(msg) >= event_size)
assert(_M.zmq_msg_more(msg) == 0)

ffi.copy(event, _M.zmq_msg_data(msg), event_size)
local addr
if event.data.connected.addr ~= NULL then

addr = ffi.string(event.data.connected.addr)
end

_M.zmq_msg_close(msg)
return event.event, event.data.connected.fd, addr
end

else
ffi.cdef([[
typedef struct { 
uint16_t event;
int32_t value;
}  zmq_event_t;
]])
local zmq_event_t = ffi.typeof("zmq_event_t")
local event_size = ffi.sizeof(zmq_event_t)
local event = ffi.new(auint16_t)
local value = ffi.new(aint32_t)

function _M.zmq_recv_event(skt, flags)
local msg = _M.zmq_msg_init(msg)
if not msg then
 return end

local ret = _M.zmq_msg_recv(msg, skt, flags)
if ret == -1 then

_M.zmq_msg_close(msg)
return
end

-- assert(_M.zmq_msg_more(msg) ~= 0)

local buf = ffi.cast(pchar_t, _M.zmq_msg_data(msg))
assert(_M.zmq_msg_size(msg) == (int16_size +  int32_size))

ffi.copy(event, buf, int16_size)
ffi.copy(value, buf +  int16_size, int32_size)

ret = _M.zmq_msg_recv(msg, skt, _M.FLAGS.ZMQ_DONTWAIT)
if ret == -1 then

_M.zmq_msg_close(msg)
return
end

local addr = _M.zmq_msg_get_data(msg)
_M.zmq_msg_close(msg)

-- assert(_M.zmq_msg_more(msg) == 0)

return event[0], value[0], addr
end

end

end

-- zmq_stopwatch_start, zmq_stopwatch_stop
do


function _M.zmq_stopwatch_start()
return libzmq3.zmq_stopwatch_start()
end

function _M.zmq_stopwatch_stop(watch)
return tonumber(libzmq3.zmq_stopwatch_stop(watch))
end

end

_M.ERRORS = require"lzmqFFI/error"
local ERRORS_MNEMO = { } 
for k,v in pairs(_M.ERRORS) do
 ERRORS_MNEMO[v] = k end

function _M.zmq_mnemoerror(errno)
return ERRORS_MNEMO[errno] or "UNKNOWN"
end

do
 -- const

_M.CONTEXT_OPTIONS = { 
ZMQ_IO_THREADS = 1;
ZMQ_MAX_SOCKETS = 2;
} 

_M.SOCKET_OPTIONS = { 
ZMQ_AFFINITY = { 4 , "RW", "u64"} ;
ZMQ_IDENTITY = { 5 , "RW", "str"} ; 
ZMQ_SUBSCRIBE = { 6 , "WO", "str_arr"} ;
ZMQ_UNSUBSCRIBE = { 7 , "WO", "str_arr"} ;
ZMQ_RATE = { 8 , "RW", "int"} ;
ZMQ_RECOVERY_IVL = { 9 , "RW", "int"} ;
ZMQ_SNDBUF = { 11, "RW", "int"} ;
ZMQ_RCVBUF = { 12, "RW", "int"} ;
ZMQ_RCVMORE = { 13, "RO", "int"} ;
ZMQ_FD = { 14, "RO", "fdt"} ;
ZMQ_EVENTS = { 15, "RO", "int"} ;
ZMQ_TYPE = { 16, "RO", "int"} ;
ZMQ_LINGER = { 17, "RW", "int"} ;
ZMQ_RECONNECT_IVL = { 18, "RW", "int"} ;
ZMQ_BACKLOG = { 19, "RW", "int"} ;
ZMQ_RECONNECT_IVL_MAX = { 21, "RW", "int"} ;
ZMQ_MAXMSGSIZE = { 22, "RW", "i64"} ;
ZMQ_SNDHWM = { 23, "RW", "int"} ;
ZMQ_RCVHWM = { 24, "RW", "int"} ;
ZMQ_MULTICAST_HOPS = { 25, "RW", "int"} ;
ZMQ_RCVTIMEO = { 27, "RW", "int"} ;
ZMQ_SNDTIMEO = { 28, "RW", "int"} ;
ZMQ_IPV4ONLY = { 31, "RW", "int"} ;
ZMQ_LAST_ENDPOINT = { 32, "RO", "str"} ;
ZMQ_ROUTER_MANDATORY = { 33, "WO", "int"} ;
ZMQ_TCP_KEEPALIVE = { 34, "RW", "int"} ;
ZMQ_TCP_KEEPALIVE_CNT = { 35, "RW", "int"} ;
ZMQ_TCP_KEEPALIVE_IDLE = { 36, "RW", "int"} ;
ZMQ_TCP_KEEPALIVE_INTVL = { 37, "RW", "int"} ;
ZMQ_TCP_ACCEPT_FILTER = { 38, "WO", "str_arr"} ;
ZMQ_DELAY_ATTACH_ON_CONNECT = { 39, "RW", "int"} ;
ZMQ_IMMEDIATE = { 39, "RW", "int"} ;
ZMQ_XPUB_VERBOSE = { 40, "RW", "int"} ;
ZMQ_ROUTER_RAW = { 41, "RW", "int"} ;
ZMQ_IPV6 = { 42, "RW", "int"} ,
ZMQ_MECHANISM = { 43, "RO", "int"} ,
ZMQ_PLAIN_SERVER = { 44, "RW", "int"} ,
ZMQ_PLAIN_USERNAME = { 45, "RW", "str"} ,
ZMQ_PLAIN_PASSWORD = { 46, "RW", "str"} ,
ZMQ_CURVE_SERVER = { 47, "RW", "int"} ,
ZMQ_CURVE_PUBLICKEY = { 48, "RW", "str"} ,
ZMQ_CURVE_SECRETKEY = { 49, "RW", "str"} ,
ZMQ_CURVE_SERVERKEY = { 50, "RW", "str"} ,
ZMQ_PROBE_ROUTER = { 51, "WO", "int"} ,
ZMQ_REQ_CORRELATE = { 52, "WO", "int"} ,
ZMQ_REQ_RELAXED = { 53, "WO", "int"} ,
ZMQ_CONFLATE = { 54, "WO", "int"} ,
ZMQ_ZAP_DOMAIN = { 55, "RW", "str"} ,
} 

_M.SOCKET_TYPES = { 
ZMQ_PAIR = 0;
ZMQ_PUB = 1;
ZMQ_SUB = 2;
ZMQ_REQ = 3;
ZMQ_REP = 4;
ZMQ_DEALER = 5;
ZMQ_ROUTER = 6;
ZMQ_PULL = 7;
ZMQ_PUSH = 8;
ZMQ_XPUB = 9;
ZMQ_XSUB = 10;
} 

_M.FLAGS = { 
ZMQ_DONTWAIT = 1;
ZMQ_SNDMORE = 2;
ZMQ_POLLIN = 1;
ZMQ_POLLOUT = 2;
ZMQ_POLLERR = 4;
} 

_M.DEVICE = { 
ZMQ_STREAMER = 1;
ZMQ_FORWARDER = 2;
ZMQ_QUEUE = 3;
} 

_M.SECURITY_MECHANISM = { 
ZMQ_NULL = 0;
ZMQ_PLAIN = 1;
ZMQ_CURVE = 2;
} 

_M.EVENTS = { 
ZMQ_EVENT_CONNECTED = 1;
ZMQ_EVENT_CONNECT_DELAYED = 2;
ZMQ_EVENT_CONNECT_RETRIED = 4;
ZMQ_EVENT_LISTENING = 8;
ZMQ_EVENT_BIND_FAILED = 16;
ZMQ_EVENT_ACCEPTED = 32;
ZMQ_EVENT_ACCEPT_FAILED = 64;
ZMQ_EVENT_CLOSED = 128;
ZMQ_EVENT_CLOSE_FAILED = 256;
ZMQ_EVENT_DISCONNECTED = 512;
} 

if ZMQ_VERSION_MAJOR >= 4 then

_M.EVENTS.ZMQ_EVENT_MONITOR_STOPPED = 1024
end

do
 local ZMQ_EVENT_ALL = 0
for _, v in pairs(_M.EVENTS) do

ZMQ_EVENT_ALL = ZMQ_EVENT_ALL +  v
end
_M.EVENTS.ZMQ_EVENT_ALL = ZMQ_EVENT_ALL
end

end

_M.inttoptr = inttoptr
_M.ptrtoint = ptrtoint

_M.strtoptr = strtoptr
_M.ptrtostr = ptrtostr

_M.serialize_ptr = serialize_ptr
_M.deserialize_ptr = deserialize_ptr

_M.vla_pollitem_t = vla_pollitem_t
_M.zmq_pollitem_t = zmq_pollitem_t
_M.zmq_msg_t = zmq_msg_t
_M.NULL = NULL
_M.bit = bit
_M.ZMQ_VERSION_MAJOR, _M.ZMQ_VERSION_MINOR, _M.ZMQ_VERSION_PATCH =
ZMQ_VERSION_MAJOR, ZMQ_VERSION_MINOR, ZMQ_VERSION_PATCH

return _M
