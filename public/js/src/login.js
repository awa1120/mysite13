console.log("login処理");

//パラメタ領域からエラー区分を取得する
var error_flag = document.getElementById('error_flag');
var error_flag_value = error_flag.value;

login_error();

function login_error(){

  if (error_flag_value == 1) {
    $("#error_info").removeClass("display_none");
  }

}