
create function sp_split(
    @c nvarchar(4000),
    @splitchar nvarchar(1)
)
returns @table  table (value nvarchar(max))
as
begin
    declare @temp nvarchar(200)
    set @c=@c+@splitchar--在最右边加上一个分隔符，用于最后的获取最右边的字符串
    while charINDEX(@splitchar,@c)>0
	   begin
		  /*
		    charINDEX(@splitchar,@c) 查找分隔符在字符串中出现的第一个位置
		    substring(@c,1, charINDEX(@splitchar,@c)-1)截取分隔符前面的字符串
		    RIGHT(@c,LEN(@c)-charINDEX(@splitchar,@c))从右边截取字符串指定长度内容即去掉字符串中已经查找到的字符串
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

