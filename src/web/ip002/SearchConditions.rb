class SearchConditions
  require 'logger'

    def initialize
    end

    def Conditions(shinseibi_s:, shinseibi_e:, hiyoubi_s:, hiyoubi_e:, shinseisya:, kenmei:, syosai:)
      logger = Logger.new('sinatra.log')
      logger.info "Conditions"
        #テーブルへアクセスするSQLを定義する。
        # 条件指定なしの場合
        sql_buys_A = "SELECT S.id,S.申請者id,S.申請日,S.費用発生日,S.費用区分,S.件名,S.詳細,S.予算コード,S.税込額,S.税抜額,S.税額,S.税率,S.備考,S.申請状況,S.取消区分,S.添付ファイル,U.name FROM shinsei S INNER JOIN users U ON S.申請者id = U.employee_id "
        sort = "order by S.id "

        # 条件指定ありの場合

        #すでにWhere句が宣言されているか確認するフラグ
        first_flag = 0

        #検索条件が空の場合、全レコードを対象に検索する。
        if shinseibi_s.empty?
          if shinseibi_e.empty?
            if hiyoubi_s.empty?
              if hiyoubi_e.empty?
                if shinseisya.empty?
                  if kenmei.empty?
                    if syosai.empty?
                      return "#{sql_buys_A} #{sort}"
                    end
                  end
                end
              end
            end
          end
        end
        
        #申請日の検索条件を設定する。
        if shinseibi_s.empty?
          if shinseibi_e.empty?
            shinseibi_where = nil
          else
            if first_flag==0
              #終了が入力されている場合
              shinseibi_where = "WHERE S.申請日 BETWEEN '00000000' AND '#{shinseibi_e}' "
              first_flag=1
            else
              shinseibi_where = "AND S.申請日 BETWEEN '00000000' AND '#{shinseibi_e}' "
            end
          end
        else
          if shinseibi_e.empty?
            if first_flag==0
              #開始が入力されている場合
              shinseibi_where = "WHERE S.申請日 BETWEEN '#{shinseibi_s}' AND '99999999' "
              first_flag=1
            else
              shinseibi_where = "AND S.申請日 BETWEEN '#{shinseibi_s}' AND '99999999' "
            end
          else
            if first_flag==0
              #開始、終了が入力されている場合
              shinseibi_where = "WHERE S.申請日 BETWEEN '#{shinseibi_s}' AND '#{shinseibi_e}' "
              first_flag=1
            else
              shinseibi_where = "AND S.申請日 BETWEEN '#{shinseibi_s}' AND '#{shinseibi_e}' "
            end
          end
        end

        #購入日の検索条件を設定する。
        if hiyoubi_s.empty?
          if hiyoubi_e.empty?
            hiyoubi_where = nil
          else
            if first_flag==0
              #終了が入力されている場合
              hiyoubi_where = "WHERE S.費用発生日 BETWEEN '00000000' AND '#{hiyoubi_e}' "
              first_flag=1
            else
              hiyoubi_where = "AND S.費用発生日 BETWEEN '00000000' AND '#{hiyoubi_e}' "
            end
          end
        else
          if hiyoubi_e.empty?
            hiyoubi_e_where = nil
           if first_flag==0
             #開始が入力されている場合
             hiyoubi_where = "WHERE S.費用発生日 BETWEEN '#{hiyoubi_s}' AND '99999999' "
             first_flag=1
           else
             hiyoubi_where = "AND S.費用発生日 BETWEEN '#{hiyoubi_s}' AND '99999999' "
           end
          else
            if first_flag==0
              #開始、終了が入力されている場合
              hiyoubi_where = "WHERE S.費用発生日 BETWEEN '#{hiyoubi_s}' AND '#{hiyoubi_e}' "
              first_flag=1
            else
              hiyoubi_where = "AND S.費用発生日 BETWEEN '#{hiyoubi_s}' AND '#{hiyoubi_e}' "
            end
          end
        end
      

        #申請者の検索条件を設定する。
        if shinseisya.empty?
          shinseisya_where = nil
        else
          if first_flag==0
            shinseisya_where = "WHERE S.申請者ID LIKE '%#{shinseisya}%' "
            first_flag=1
          else
            shinseisya_where = "AND S.申請者ID LIKE '%#{shinseisya}%' "
          end
        end

        #品名の検索条件を設定する。
        if kenmei.empty?
          kenmei_where = nil
        else
          if first_flag==0
            kenmei_where = "WHERE S.件名 LIKE '%#{kenmei}%' "
            first_flag=1
          else
            kenmei_where = "AND S.件名 LIKE '%#{kenmei}%' "
          end
        end

        #メーカーの検索条件を設定する。
        if syosai.empty?
          syosai_where = nil
        else
          if first_flag==0
            syosai_where = "WHERE S.詳細 LIKE '%#{syosai}%' "
            first_flag=1
          else
            syosai_where = "AND S.詳細 LIKE '%#{syosai}%' "
          end
        end

        sql = "#{sql_buys_A} #{shinseibi_where} #{hiyoubi_where} #{shinseisya_where} #{kenmei_where} #{syosai_where} #{sort}"
        return sql
    end
end