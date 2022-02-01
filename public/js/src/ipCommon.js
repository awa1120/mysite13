console.log("#ipCommon.js")

/**************************
 * スラッシュ編集を行うFunction
 **************************/
 function toSlash(obj){
    if(new RegExp(/^[0-9]{8}$/).test(obj.value)){
      var str = obj.value.trim();
      var y = str.substr(0,4);
      var m = str.substr(4,2);
      var d = str.substr(6,2);
      obj.value = y + "/" + m + "/" + d;
    }
  }
   
  /**************************
   * スラッシュ編集を解除するFunction
   **************************/
  function offSlash(obj){
    var reg = new RegExp("/", "g");
    var chgVal = obj.value.replace(reg, "");
    if(!isNaN(chgVal)){
      obj.value = chgVal;  //値セット
      obj.select();        //全選択
    }
  }