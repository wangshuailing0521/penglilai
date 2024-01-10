
create function sp_split(
    @c nvarchar(4000),
    @splitchar nvarchar(1)
)
returns @table  table (value nvarchar(max))
as
begin
    declare @temp nvarchar(200)
    set @c=@c+@splitchar--�����ұ߼���һ���ָ������������Ļ�ȡ���ұߵ��ַ���
    while charINDEX(@splitchar,@c)>0
	   begin
		  /*
		    charINDEX(@splitchar,@c) ���ҷָ������ַ����г��ֵĵ�һ��λ��
		    substring(@c,1, charINDEX(@splitchar,@c)-1)��ȡ�ָ���ǰ����ַ���
		    RIGHT(@c,LEN(@c)-charINDEX(@splitchar,@c))���ұ߽�ȡ�ַ���ָ���������ݼ�ȥ���ַ������Ѿ����ҵ����ַ���
		  */
		  set @temp=substring(@c,1, charINDEX(@splitchar,@c)-1)
		  if(len(@temp)>0)
			 begin
				insert @table values(@temp)
			 end
		   set @c=RIGHT(@c,LEN(@c)-charINDEX(@splitchar,@c))
	   end
    return 
end

