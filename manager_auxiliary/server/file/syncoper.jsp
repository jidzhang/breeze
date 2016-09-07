<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="java.util.regex.*"%>
<%@ page import="com.breeze.framwork.netserver.tool.ContextMgr"%>
<%@ page import="com.breeze.framwork.databus.BreezeContext" %>

<%@ include  file="../module/result.jsp"%>
<%
   /*!本类是一个处理文件同步的类
     1.类似SVN的操作，客户端操作文件时，会申请一个锁，如果没有其他人在使用这个锁，那么就把这个锁给这个客户端使用
     2.特殊的地方，svn是所一个大文件，而本类所的是一个特殊的有结构的文件，即可以用BreezeContext表示的数据结构
     3.因为是结构体，所以所示可以进行局部锁的，当然也有全局锁
     4.这个后台也保留完整的全局文件内容，当客户端数据是旧的时候，服务端的数据会下放数据给客户端
     5.下放数据给客户端的还是结构体，即BreezeContext的内容
   */
%>
<%!
  //!这个片段用于定义全局变量，这些全局变量用this.xxx直接访问，这段不用写代码
  
  /**
  * allData是一个记录全局数据的对象，其结构如下：
  * {
  *    {  //fileName表示客户端传入的文件名，即要保存和同步的文件名
  *       fileName:"filename"
  *       {
  *         lockKey:{//每一个锁的锁id值，其实就allData[fileName]下面的子对象的key例如allData.["c.file"].a这里a就是lockKey，_$_whole这个key是特殊的，表示全文件
  *           content:{}
  *        } 
  *       }
  *    }
  * }
  */
  BreezeContext allData = new BreezeContext();
  //超时设置
  long timeOut=10000;
  
  //初始版本设置
  int  originalVersion=1;
  
  /**
  *lockInfo是对象所信息，配套allData结构使用的，其结构如下：
  *  {
  *     fileName:{和allData的fileName对应结构
  *        lastModify:最后一次修改的时间戳
  *        lockKey:{//每一个锁的锁id值，其实就allData[fileName]下面的子对象的key例如allData.["c.file"].a这里a就是lockKey，_$_whole这个key是特殊的，表示全文件
  *            lastModify:这个key上次申请的时间
  *            version:这个key的版本号
  *            lockuserid:锁这个对象的用户id，这里就是用sessionid表示，如果这个值不存在未null，就说明这个结构没有被锁，下面代码说明不再赘述了
  *        }
  *     }
  *  }
  */
  BreezeContext lockInfo = new BreezeContext();
%>


<%!
   
    //定义公共方法代码块
    
    //返回并显示结果方法
    public String returnResult(int code,BreezeContext contentCtx,BreezeContext lockInfoCtx,BreezeContext msg){   
        BreezeContext returnData = new BreezeContext(); 
	    returnData.setContextByPath("content",contentCtx);
	    returnData.setContextByPath("lockInfo", lockInfoCtx);
	    returnData.setContextByPath("msg", msg);
	  	return genResult(code,returnData);   
	 }
	 
	//获取文件和指定Key文件
    public BreezeContext getFile(String fileName,String lockKey){   
	    //存在性标记
	    int isExist=0;
   
	    //保存当前需要寻找的文件和锁信息
	    BreezeContext currentFileCtx=new BreezeContext(null);
        BreezeContext currentFileContentCtx=new BreezeContext(null);  
    
	    //文件下标  
	    int index=0;
	    
	    //判断文件是否存在于列表中
	    for(int i=0;i<this.allData.getArraySize();i++)
	    {
	       if(!this.allData.getContext(i).isNull())
	       {
	       	   
	           //判断是否为指定文件
		       if(this.allData.getContext(i).getContextByPath("fileName").toString().equals(fileName))
		       {
		        isExist=1;
		        currentFileCtx=this.allData.getContext(i);
	            index=i;  
	            
		        //如果是全局锁
		        if(lockKey.equals("_$_whole"))
		        {
		           currentFileContentCtx=currentFileCtx.getContextByPath("content");
		        }
		        else
		        {
		           for(int x=0;x<currentFileCtx.getContextByPath("content").getArraySize();x++)
		          {
		             if(lockKey.equals(currentFileCtx.getContextByPath("content").getContext(x).getContextByPath("lockKey").toString()))
		             {
		                currentFileContentCtx=currentFileCtx.getContextByPath("content").getContext(x);
		                break;
		             }
		          } 
		        }    
		          
		        break;
		       }
	       }
	    
	    }
	    
	    BreezeContext returnData = new BreezeContext(); 
	    returnData.setContextByPath("index",new BreezeContext(index));
	    returnData.setContextByPath("fileContent", currentFileCtx);
	    returnData.setContextByPath("keyContent", currentFileContentCtx);
	    returnData.setContextByPath("result", new BreezeContext(isExist));
	  	return returnData;
	}
	
	
	//获取锁信息
    public BreezeContext getLock(String fileName,String lockKey){   
	    //存在性标记
	    int isExist=0;
   
	    //保存当前需要寻找的文件和锁信息
	    BreezeContext currentLockCtx=new BreezeContext(null);
        BreezeContext currentLockKeyContentCtx=new BreezeContext(null);
  
	    //文件下标  
	    int index=0;

	    
	    //判断文件是否存在于列表中
	    for(int j=0;j<this.lockInfo.getArraySize();j++)
	    {
           if(!this.lockInfo.getContext(j).isNull())
           {
           	     if(this.lockInfo.getContext(j).getContextByPath("fileName").toString().equals(fileName))
			       {
			         isExist=1;
			         currentLockCtx=this.lockInfo.getContext(j);
			         index=j;
			         
		              
			          for(int x=0;x<currentLockCtx.getContextByPath("content").getArraySize();x++)
			          {
			             if(!currentLockCtx.getContextByPath("content").getContext(x).isNull())
			             {
				              if(currentLockCtx.getContextByPath("content").getContext(x).getContextByPath("lockKey").toString().equals(lockKey))
				             {
				                currentLockKeyContentCtx=currentLockCtx.getContextByPath("content").getContext(x);
				                break;
				             }
			             }    
			          } 
			       
			         }
			         break;
          }  
	    }
	
	    
	    
	    
	    BreezeContext returnData = new BreezeContext(); 
	    returnData.setContextByPath("index",new BreezeContext(index));
	    returnData.setContextByPath("lockContent", currentLockCtx);
	    returnData.setContextByPath("keyContent", currentLockKeyContentCtx);
	    returnData.setContextByPath("result", new BreezeContext(isExist));
	  	return returnData;
	}
	
	//获取文件
    public BreezeContext getFile(String fileName){   
	    //存在性标记
	    int isExist=0;
   
	    //保存当前需要寻找的文件和锁信息
	    BreezeContext currentFileCtx=new BreezeContext(null);   
    
	    //文件下标  
	    int index=0;
	    
	    //判断文件是否存在于列表中
	    for(int i=0;i<this.allData.getArraySize();i++)
	    {
	        if(!this.allData.getContext(i).isNull())
	       {
		       //如果指定文件找到
		       if(this.allData.getContext(i).getContextByPath("fileName").toString().equals(fileName))
		       {
		        isExist=1;
		        currentFileCtx=this.allData.getContext(i);
	
		        index=i;    
		        break;
		       }
	       }
	    }
	    
	    BreezeContext returnData = new BreezeContext(); 
	    returnData.setContextByPath("index",new BreezeContext(index));
	    returnData.setContextByPath("content", currentFileCtx);
	    returnData.setContextByPath("result", new BreezeContext(isExist));
	  	return returnData;
	}
	
	
	//获取锁信息
    public BreezeContext getLock(String fileName){   
	    //存在性标记
	    int isExist=0;
   
	    //保存当前需要寻找的文件和锁信息
	    BreezeContext currentCtxtmp=new BreezeContext(null);   
    
	    //文件下标  
	    int index=0;
	    
	       //判断文件是否存在于列表中
	    for(int j=0;j<this.lockInfo.getArraySize();j++)
	    {
	      if(!this.lockInfo.getContext(j).isNull())
	      {
	      	if(this.lockInfo.getContext(j).getContextByPath("fileName").toString().equals(fileName))
		       {
		         isExist=1;
		         currentCtxtmp=this.lockInfo.getContext(j);
		         break;
		       }
	      }
	    }
	    
	    BreezeContext returnData = new BreezeContext(); 
	    returnData.setContextByPath("index",new BreezeContext(index));
	    returnData.setContextByPath("content", currentCtxtmp);
	    returnData.setContextByPath("result", new BreezeContext(isExist));
	  	return returnData;
	}
	
	//是否存在全局锁
    public BreezeContext isWholeLockExist(String fileName){   
        
        BreezeContext wholeLock=new BreezeContext();
        wholeLock.setContextByPath("content",new BreezeContext(null));
		wholeLock.setContextByPath("index",new BreezeContext(null));
        
	    boolean isExist=false;
	    //判断文件是否存在于列表中
	    for(int j=0;j<this.lockInfo.getArraySize();j++)
	    {
	       if(this.lockInfo.getContext(j).getContextByPath("fileName").toString().equals(fileName))
	       {
	          BreezeContext tmpLockKey=this.lockInfo.getContext(j).getContextByPath("content");
	          for(int x=0;x<tmpLockKey.getArraySize();x++)
	          {
	             if(!tmpLockKey.getContext(x).isNull())
	             {
		             if(tmpLockKey.getContext(x).getContextByPath("lockKey").toString().equals("_$_whole"))
		             {
		                wholeLock.setContextByPath("content",tmpLockKey.getContext(x));
		                wholeLock.setContextByPath("index",new BreezeContext(x));
		                isExist=true;
		                break;
		             }
	             }
	          } 
	     
	         break;
	       }
	    }
	    return wholeLock;
	}
	
	
	//添加新文件信息
    public BreezeContext addFileName(BreezeContext content , BreezeContext lastModify ,String fileName){   
	   BreezeContext fileCtx = new BreezeContext();
	   fileCtx.setContextByPath("fileName",new BreezeContext(fileName));
	   fileCtx.setContextByPath("content", content);	    
	   this.allData.pushContext(fileCtx);
	   return fileCtx;
	}
	
	//添加新文件锁信息
    public BreezeContext addLockInfo(BreezeContext content , BreezeContext lastModify ,String fileName){   
	   BreezeContext lockCtx = new BreezeContext();
	   lockCtx.setContextByPath("fileName",new BreezeContext(fileName));
	   lockCtx.setContextByPath("lastModify",lastModify);
	   lockCtx.setContextByPath("version",new BreezeContext(this.originalVersion));
	   lockCtx.setContextByPath("content", content);
	 /*  
	   BreezeContext lockContentCtx = new BreezeContext();
	   
	   for(int i=0;i<content.getArraySize();i++)
	   {
	   	    BreezeContext lockContentCtxTmp = new BreezeContext();
	   	    lockContentCtxTmp.setContextByPath("lockKey",content.getContext(i).getContextByPath("lockKey"));
	   		lockContentCtxTmp.setContextByPath("lastModify",new BreezeContext());
			lockContentCtxTmp.setContextByPath("version",new BreezeContext(this.originalVersion));
			lockContentCtxTmp.setContextByPath("lockuserid",new BreezeContext());
					    
	   }*/
	   this.lockInfo.pushContext(lockCtx);
	   return lockCtx;
	}
	
		//设置对象锁信息
    public BreezeContext setLockKey(String fileName,String lockKey,int index,String version,String lastModify,String sessionId){   
       boolean isExist=false;
       BreezeContext returnData=new BreezeContext();
        //清除自身锁
        for(int j=0;j<this.lockInfo.getArraySize();j++)
	    {
	          BreezeContext tmpLockKey=this.lockInfo.getContext(j);   
	          if(!this.lockInfo.getContext(j).isNull())
	          {
		          if(this.lockInfo.getContext(j).getContextByPath("fileName").toString().equals(fileName))
		          {
		             if(tmpLockKey.getContextByPath("content").getArraySize()<=0)
		             {
		                    BreezeContext currentLockCtxData = new BreezeContext();
						    currentLockCtxData.setContextByPath("lastModify",new BreezeContext(lastModify));
						    currentLockCtxData.setContextByPath("version",new BreezeContext(version));
						    currentLockCtxData.setContextByPath("lockuserid",new BreezeContext(sessionId));
						    currentLockCtxData.setContextByPath("lockKey",new BreezeContext(lockKey)); 
						    tmpLockKey.getContextByPath("content").pushContext(currentLockCtxData);
						    tmpLockKey.setContextByPath("lastModify",new BreezeContext(lastModify));    
						    this.lockInfo.setContext(j,tmpLockKey);
						    returnData=tmpLockKey;
		             }
		             else
		             {
		              for(int x=0;x<tmpLockKey.getContextByPath("content").getArraySize();x++)
			          {
		                    if(!tmpLockKey.getContextByPath("content").getContext(x).isNull())
			                {
				             if(tmpLockKey.getContextByPath("content").getContext(x).getContextByPath("lockKey").toString().equals(lockKey) )
				             {
				                BreezeContext currentLockCtxData = new BreezeContext();
							    currentLockCtxData.setContextByPath("lastModify",new BreezeContext(lastModify));
							    currentLockCtxData.setContextByPath("version",new BreezeContext(version));
							    currentLockCtxData.setContextByPath("lockuserid",new BreezeContext(sessionId));
							    currentLockCtxData.setContextByPath("lockKey",new BreezeContext(lockKey)); 
							    
							    tmpLockKey.getContextByPath("content").setContext(x,currentLockCtxData);
							    tmpLockKey.setContextByPath("lastModify",new BreezeContext(lastModify));    
							    this.lockInfo.setContext(j,tmpLockKey);
							    returnData=tmpLockKey;
							    isExist=true;
				             }
				             else
				             {
				                if(tmpLockKey.getContextByPath("content").getContext(x).getContextByPath("lockuserid").toString().equals(sessionId))
					            {
					                tmpLockKey.getContextByPath("content").setContext(x,new BreezeContext(null));
					                this.lockInfo.setContext(j,tmpLockKey);
					            }
				             }
				             
				             //没有找到现存的锁文件
				             if(!isExist && x==tmpLockKey.getContextByPath("content").getArraySize()-1)
				             {
				                BreezeContext currentLockCtxData = new BreezeContext();
							    currentLockCtxData.setContextByPath("lastModify",new BreezeContext(lastModify));
							    currentLockCtxData.setContextByPath("version",new BreezeContext(version));
							    currentLockCtxData.setContextByPath("lockuserid",new BreezeContext(sessionId));
							    currentLockCtxData.setContextByPath("lockKey",new BreezeContext(lockKey)); 
							    
							    tmpLockKey.getContextByPath("content").pushContext(currentLockCtxData);
							    tmpLockKey.setContextByPath("lastModify",new BreezeContext(lastModify));    
							    this.lockInfo.setContext(j,tmpLockKey);
							    returnData=tmpLockKey;
				             }
				          }else
				          {
	//没有找到现存的锁文件
				             if(!isExist && x==tmpLockKey.getContextByPath("content").getArraySize()-1)
				             {
				                BreezeContext currentLockCtxData = new BreezeContext();
							    currentLockCtxData.setContextByPath("lastModify",new BreezeContext(lastModify));
							    currentLockCtxData.setContextByPath("version",new BreezeContext(version));
							    currentLockCtxData.setContextByPath("lockuserid",new BreezeContext(sessionId));
							    currentLockCtxData.setContextByPath("lockKey",new BreezeContext(lockKey)); 
							    
							    tmpLockKey.getContextByPath("content").pushContext(currentLockCtxData);
							    tmpLockKey.setContextByPath("lastModify",new BreezeContext(lastModify));    
							    this.lockInfo.setContext(j,tmpLockKey);
							    returnData=tmpLockKey;
				             }
				          }
			          }
		             }
	
		          }
		          else
		          {  
			          for(int x=0;x<tmpLockKey.getContextByPath("content").getArraySize();x++)
			          {
			             if(tmpLockKey.getContextByPath("content").getContext(x).getContextByPath("lockuserid").toString().equals(sessionId) )
			             {
			                tmpLockKey.getContextByPath("content").setContext(x,new BreezeContext(null));
			                this.lockInfo.setContext(j,tmpLockKey);
			             }
			          }  
		          }          	
	          }

	    } 

	    return returnData;
	}
	

		//设置对象锁信息
    public BreezeContext updateLockKey(String fileName,String lockKey,int wholdVersion,int version,String lastModify,String sessionId){   
       boolean isExist=false;
       BreezeContext returnData=new BreezeContext(null);
        //清除自身锁
        for(int j=0;j<this.lockInfo.getArraySize();j++)
	    {
	          BreezeContext tmpLockKey=this.lockInfo.getContext(j);   
	          
	          if(this.lockInfo.getContext(j).getContextByPath("fileName").toString().equals(fileName))
	          {
	             if(tmpLockKey.getContextByPath("content").getArraySize()<=0)
	             {
	                    BreezeContext currentLockCtxData = new BreezeContext();
					    currentLockCtxData.setContextByPath("lastModify",new BreezeContext(lastModify));
					    currentLockCtxData.setContextByPath("version",new BreezeContext(version+1));
					    currentLockCtxData.setContextByPath("lockuserid",new BreezeContext(sessionId));
					    currentLockCtxData.setContextByPath("lockKey",new BreezeContext(lockKey)); 
					    tmpLockKey.getContextByPath("content").pushContext(currentLockCtxData);
					    tmpLockKey.setContextByPath("lastModify",new BreezeContext(lastModify));    
					    tmpLockKey.setContextByPath("version",new BreezeContext(wholdVersion+1));  
					    this.lockInfo.setContext(j,tmpLockKey);
					    returnData=tmpLockKey;
	             }
	             else
	             {
	              for(int x=0;x<tmpLockKey.getContextByPath("content").getArraySize();x++)
		          {
	                    if(!tmpLockKey.getContextByPath("content").getContext(x).isNull())
		                {
			             if(tmpLockKey.getContextByPath("content").getContext(x).getContextByPath("lockKey").toString().equals(lockKey) )
			             {
			                BreezeContext currentLockCtxData = new BreezeContext();
						    currentLockCtxData.setContextByPath("lastModify",new BreezeContext(lastModify));
						    currentLockCtxData.setContextByPath("version",new BreezeContext(version+1));
						    currentLockCtxData.setContextByPath("lockuserid",new BreezeContext(sessionId));
						    currentLockCtxData.setContextByPath("lockKey",new BreezeContext(lockKey)); 
						    
						    tmpLockKey.getContextByPath("content").setContext(x,currentLockCtxData);
						    tmpLockKey.setContextByPath("lastModify",new BreezeContext(lastModify));  
						    tmpLockKey.setContextByPath("version",new BreezeContext(wholdVersion+1));  
						    this.lockInfo.setContext(j,tmpLockKey);
						    returnData=tmpLockKey;
						    isExist=true;
			             }
			             else
			             {
			                if(tmpLockKey.getContextByPath("content").getContext(x).getContextByPath("lockuserid").toString().equals(sessionId))
				            {
				                tmpLockKey.getContextByPath("content").setContext(x,new BreezeContext(null));
				                this.lockInfo.setContext(j,tmpLockKey);
				            }
			             }
			             
			             //没有找到现存的锁文件
			             if(!isExist && x==tmpLockKey.getContextByPath("content").getArraySize()-1)
			             {
			                BreezeContext currentLockCtxData = new BreezeContext();
						    currentLockCtxData.setContextByPath("lastModify",new BreezeContext(lastModify));
						    currentLockCtxData.setContextByPath("version",new BreezeContext(version+1));
						    currentLockCtxData.setContextByPath("lockuserid",new BreezeContext(sessionId));
						    currentLockCtxData.setContextByPath("lockKey",new BreezeContext(lockKey)); 
						    
						    tmpLockKey.getContextByPath("content").pushContext(currentLockCtxData);
						    tmpLockKey.setContextByPath("lastModify",new BreezeContext(lastModify)); 
						    tmpLockKey.setContextByPath("version",new BreezeContext(wholdVersion+1));  
						    this.lockInfo.setContext(j,tmpLockKey);
						    returnData=tmpLockKey;
			             }
			          }else
			          {
//没有找到现存的锁文件
			             if(!isExist && x==tmpLockKey.getContextByPath("content").getArraySize()-1)
			             {
			                BreezeContext currentLockCtxData = new BreezeContext();
						    currentLockCtxData.setContextByPath("lastModify",new BreezeContext(lastModify));
						    currentLockCtxData.setContextByPath("version",new BreezeContext(version+1));
						    currentLockCtxData.setContextByPath("lockuserid",new BreezeContext(sessionId));
						    currentLockCtxData.setContextByPath("lockKey",new BreezeContext(lockKey)); 
						    
						    tmpLockKey.getContextByPath("content").pushContext(currentLockCtxData);
						    tmpLockKey.setContextByPath("lastModify",new BreezeContext(lastModify));  
						    tmpLockKey.setContextByPath("version",new BreezeContext(wholdVersion+1));  
						    this.lockInfo.setContext(j,tmpLockKey);
						    returnData=tmpLockKey;
			             }
			          }
		          }
	             }

	          }
	          else
	          {  
		          for(int x=0;x<tmpLockKey.getContextByPath("content").getArraySize();x++)
		          {
		             if(tmpLockKey.getContextByPath("content").getContext(x).getContextByPath("lockuserid").toString().equals(sessionId) )
		             {
		                tmpLockKey.getContextByPath("content").setContext(x,new BreezeContext(null));
		                this.lockInfo.setContext(j,tmpLockKey);
		             }
		          }  
	          }
	    } 

	    return returnData;
	}
	
	
	//删除锁
    public void deleteLockKey(String fileName,String lockKey){   
	    for(int i=0;i<this.lockInfo.getArraySize();i++)
	    {
	       //如果指定文件找到
	       if(this.lockInfo.getContext(i).getContextByPath("fileName").toString().equals(fileName))
	       {
	           BreezeContext lockKeyArr=  this.lockInfo.getContext(i);
	           //编辑清除锁信息文件
	           for(int j=0;j<lockKeyArr.getContextByPath("content").getArraySize();j++)
			    {
			      if(!lockKeyArr.getContextByPath("content").getContext(j).isNull())
			      {
			       //文件锁内容清除
			       if(lockKeyArr.getContextByPath("content").getContext(j).getContextByPath("lockKey").toString().equals(lockKey))
			       {
			        
			         lockKeyArr.getContextByPath("content").setContext(j,new BreezeContext());
				     this.lockInfo.setContext(i,lockKeyArr);
			         break;
			       }
			      }
			    }
	       }
	    }
	}
	
	//删除超时文件
    public void deleteTimeoutFile(Long currentTime){   
	   //判断文件是否存在于列表中
	    for(int i=0;i<this.allData.getArraySize();i++)
	    {
	    	if(!this.allData.getContext(i).isNull())
	    	{
		    	//编辑清除锁信息文件
		         for(int j=0;j<this.lockInfo.getArraySize();j++)
				{
	                if(!this.lockInfo.getContext(j).isNull() && !this.allData.getContext(i).isNull())
	                {
	                	if(this.lockInfo.getContext(j).getContextByPath("fileName").toString().equals(this.allData.getContext(i).getContextByPath("fileName").toString()))
				       {
				       	 //判断大文件是否超时
				         if(currentTime-Long.parseLong(this.lockInfo.getContext(j).getContextByPath("lastModify").toString())>this.timeOut)
				         {
				           this.allData.setContext(i,new BreezeContext(null));
				           this.lockInfo.setContext(j,new BreezeContext(null));
				         }
				         else  
				         {
				         	    //编辑清除锁信息文件
						         for(int x=0;x<this.lockInfo.getContext(j).getContextByPath("content").getArraySize();x++)
								{
									if(!this.lockInfo.getContext(j).getContextByPath("content").getContext(x).isNull())
									{
										if(currentTime-Long.parseLong(this.lockInfo.getContext(j).getContextByPath("content").getContext(x).getContextByPath("lastModify").toString())>this.timeOut)
										{
											 String lockKeyTmpStr=this.lockInfo.getContext(j).getContextByPath("content").getContext(x).getContextByPath("lockKey").toString();
											 this.lockInfo.getContext(j).getContextByPath("content").setContext(x,new BreezeContext(null));
				                          
				                             //将锁对应的文件内容置空
										     for(int k=0;k<this.allData.getContext(i).getContextByPath("content").getArraySize();k++)
										     {
										     	if(lockKeyTmpStr.equals(this.allData.getContext(i).getContextByPath("content").getContext(k).getContextByPath("lockKey").toString()))
										     	{
										     		this.allData.getContext(i).getContextByPath("content").setContext(k,new BreezeContext(null));
										     	}
										     }
										}
									}
								}
				         }
				       }	
	                }
				
				    
				      
				}	
	    	}

			   
	    }
	}
	
	//文件提交
    public BreezeContext commit(String lockKey,BreezeContext content,String fileName,long lastModify,int wholdVersion,int version,String sessionId){   
       BreezeContext returnData=new BreezeContext();
       boolean isLockExist=false;
       //判断是否为全局锁
	   if(lockKey.equals("_$_whole"))
	   {
	   	   //判断文件是否存在于列表中
		    for(int i=0;i<this.allData.getArraySize();i++)
		    {
		    	//文件锁内容清除
				if(this.allData.getContext(i).getContextByPath("fileName").toString().equals(fileName))
				{
					BreezeContext fileCtxTmp = this.allData.getContext(i);
					fileCtxTmp.setContextByPath("content", content);
					this.allData.setContext(i,fileCtxTmp); 
					//更新锁状态
			    	BreezeContext fileLockInfoTmp=this.updateLockKey(fileName,lockKey,wholdVersion,version,Long.toString(lastModify),sessionId);
					returnData.setContextByPath("lock",fileLockInfoTmp);
					returnData.setContextByPath("file",this.allData.getContext(i));
				
				  break;	
				}
		   
		    }
	   }
	   else
	   {
            //判断文件是否存在于列表中
		    for(int i=0;i<this.allData.getArraySize();i++)
		    {
		    	//文件锁内容清除
				if(this.allData.getContext(i).getContextByPath("fileName").toString().equals(fileName))
				{		
					if(this.allData.getContext(i).getContextByPath("content").getArraySize()<=0)
					{
						BreezeContext fileLockContentCtxTmp =this.allData.getContext(i).getContextByPath("content");
						BreezeContext fileLockContentItem =new BreezeContext();
						fileLockContentItem.setContextByPath("content",content);
						fileLockContentItem.setContextByPath("lockKey",new BreezeContext(lockKey));
						fileLockContentCtxTmp.pushContext(fileLockContentItem);
	     							       	  
						BreezeContext fileCtxTmp = this.allData.getContext(i);
	                    fileCtxTmp.setContextByPath("content", fileLockContentCtxTmp);
						this.allData.setContext(i,fileCtxTmp); 
					}else
					{
		                 //编辑清除锁信息文件
				         for(int k=0;k<this.allData.getContext(i).getContextByPath("content").getArraySize();k++)
						{
							//判断锁健值是否匹配
							if(this.allData.getContext(i).getContextByPath("content").getContext(k).getContextByPath("lockKey").toString().equals(lockKey))
							{
									   BreezeContext fileLockCtxTmp = this.allData.getContext(i).getContextByPath("content").getContext(k);	             
								       fileLockCtxTmp.setContextByPath("content",content);
	         
								       BreezeContext fileLockContentCtxTmp =this.allData.getContext(i).getContextByPath("content");
								       fileLockContentCtxTmp.setContext(k,fileLockCtxTmp);
								           
								           							       	  
								       BreezeContext fileCtxTmp = this.allData.getContext(i);
	                                   fileCtxTmp.setContextByPath("content", fileLockContentCtxTmp);
						               this.allData.setContext(i,fileCtxTmp); 
						               isLockExist=true;
							}
							
							//指定文件对象未找到，添加该文件对象
							if(!isLockExist && k==this.allData.getContext(i).getContextByPath("content").getArraySize()-1)
							{
								       BreezeContext fileLockContentCtxTmp =this.allData.getContext(i).getContextByPath("content");
	     							   	BreezeContext fileLockContentItem =new BreezeContext();
										fileLockContentItem.setContextByPath("content",content);
										fileLockContentItem.setContextByPath("lockKey",new BreezeContext(lockKey));
										fileLockContentCtxTmp.pushContext(fileLockContentItem);  
										
								       BreezeContext fileCtxTmp = this.allData.getContext(i);
	                                   fileCtxTmp.setContextByPath("content", fileLockContentCtxTmp);
						               this.allData.setContext(i,fileCtxTmp); 		
							}
							
							
						}
					}
                    
                    //更新锁状态
                    BreezeContext fileLockInfoTmp=this.updateLockKey(fileName,lockKey,wholdVersion,version,Long.toString(lastModify),sessionId);
					returnData.setContextByPath("lock",fileLockInfoTmp);
					returnData.setContextByPath("file",this.allData.getContext(i));
		
				  break;	
				}
		   
		    }
	   }
	   
	   return returnData;
	}
%>


<%
   //!这一段是接收客户端的参数，参数包括
   
   String jsonStr=request.getParameter("data");
   
   BreezeContext root = ContextTools.getBreezeContext4Json(jsonStr);

   //第一个参数是operType表示操作类型，有四种：
   //1.appFile  申请文件，看看这个文件是否已经在申请在内存中
   //2.setAllFile 上传整个结构对象到内存中，就是当一个文件是全新的情况下，干这个事情
   //3.appLock  申请某个对象的锁
   //4.checkin  提交结果，但是不释放对象锁
   
    //获取operType内容
 
    BreezeContext operTypeCtx =  root.getContextByPath("param.operType");
 
    if (operTypeCtx == null || operTypeCtx.isNull()){
       response.getWriter().println("传入参数不能为空！");
       return;
    }
    String operType = operTypeCtx.toString();
      
    //第二个参数是param,这个参数本身就是json结构，不必解析成字符串类型了，参见如上方式获取
  
%>

<%
  //!处理如果类型是appFile情况
  if("appFile".equals(operType)){
    /*
    *参数：这个类型情况下param参数的结构：
    * {"fileName":"fdsafads"}
    */
    /**
    *其返还的结果对象结构如下：
    *{
    *   code:0表示成功，将正常返还数据，下面data就是数据内容, 1表示文件在内存中不存在
    *   data:{
    *        content:{数据内容
    *        },
    *        lockInfo:{//对应这个文件的锁内容，就是成员变量lockInfo对应文件名下的所有内容
    *        }
    *   }
    *}
    */
    /**
    *处理逻辑就是从客户端获取到fileName到this.allData中获取数据，然后根据结果要求返还
    *注意：要检查this.lockInfo中的lastModify时间戳，最后修改时间不能超过10分钟，
    *如果扫描操作10分钟，还要将这个fileName的内容删除,就是设置这个对象为null
    */ 
    
    BreezeContext fileNameCtx =  BreezeContext.getObjectByPath("param.param.fileName",root);
  // response.getWriter().println(this.allData);
    //清理超时文件
    this.deleteTimeoutFile(System.currentTimeMillis());

       
   
    //获取文件信息 
    BreezeContext fileData = this.getFile(fileNameCtx.toString());
    BreezeContext currentFileCtx =fileData.getContextByPath("content");  
    BreezeContext isFileExist =fileData.getContextByPath("result");  
    
    //获取文件锁信息
    BreezeContext lockData = this.getLock(fileNameCtx.toString());
    BreezeContext currentLockCtx =lockData.getContextByPath("content");  

    //判断文件是否存在
    if(isFileExist.toString().equals("1"))
    {
      //文件存在返回文件数据
  	  response.getWriter().println(this.returnResult(0,currentFileCtx,currentLockCtx,new BreezeContext("获取文件成功！")));
    }else{
      //文件不存在
	   response.getWriter().println(this.returnResult(1,currentFileCtx,currentLockCtx,new BreezeContext("文件不存在！")));	
    }
    
   
  
  }
%>
<%
  //!处理类型是setAllFile情况
  if("setAllFile".equals(operType)){
    /**
    *参数：这个类型情况下的param的结构如下
    * {
    *    fileName:申请的文件名
    *    content:{//这里是实际的文件内容
    *    }
    * }
    */
    /**
    *返回结果如下：
    * {
    *    code:0表示成功，11表示该文件已经有内容，不允许上传，而其真正的值如下面data成员所示，其他情况就返回错误结果码表示错误即可，不返回数据
    *    data:{
    *        content:{数据内容
    *        },
    *        lockInfo:{//对应这个文件的锁内容，就是成员变量lockInfo对应文件名下的所有内容
    *        }
    *   }
    * }
    */
    /**
    * 处理逻辑：
    * 根据上传参数的fileName判断this内存中是否存在值，如果存在值，就返回11并把对应内存信息返回，否则将上报的对象参数content的内容设置到allData中
    * 要进行allData数据扫描，把超时的数据设置为null
    * 注意：上传设置数据的话，要更新lastModify时间
    */
    
    BreezeContext fileNameCtx =  BreezeContext.getObjectByPath("param.param.fileName",root);
    
    //清理超时文件
    this.deleteTimeoutFile(System.currentTimeMillis());
    

    
    //获取文件信息
    BreezeContext fileData = this.getFile(fileNameCtx.toString());
    BreezeContext currentFileCtx =fileData.getContextByPath("content");  
    BreezeContext isFileExist =fileData.getContextByPath("result");  
    
    //获取锁信息
    BreezeContext lockData = this.getLock(fileNameCtx.toString());
    BreezeContext currentLockCtx =lockData.getContextByPath("content");  


    //判断文件是否存在
    if(isFileExist.toString().equals("1"))
    {
       response.getWriter().println(this.returnResult(11,currentFileCtx,currentLockCtx,new BreezeContext("文件已存在！")));
    }else{
       //最后修改时间
       BreezeContext lastModify= new BreezeContext(System.currentTimeMillis());
       
       //上传文件	   
	   currentFileCtx=this.addFileName(BreezeContext.getObjectByPath("param.param.content",root), lastModify,fileNameCtx.toString());
	   
	   //上传文件锁
	   currentLockCtx=this.addLockInfo(new BreezeContext(), lastModify,fileNameCtx.toString());
	   
	   response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("新文件上传成功！")));
	
    }
    


  }
%>

<%
    //!处理类型是appLock情况
    if("appLock".equals(operType)){
    /**
    * 参数:这个类型情况下的param的结构如下：
    * {
    *    fileName:文件名
    *    lockKey:要所的对象key，注意；如果要锁全局锁，这里填_$_whole
    *    version:当前这个要锁对象的版本号
    * }
    */
    /**
    *  返回的结构如下：
    *  {
    *    code:结果码0表示成功；11表示版本不对，不让锁，这个时候会下发新版本;12表示已经被其他人锁了，不能锁;其他情况返回其他结果码 13表示文件不存在
    *    data:{//仅当结果码为11时，才返回数据
    *       content{//对应lockKey的数据，注意不要返回全部数据，除非key是_$_whole
    *       },
    *       lockInfo{//同样也是返回局部的本次lockKey对应的数据，不要返回全部数据
    *       }
    *    }
    *  }
    */
    /**
    *  处理逻辑：
    *  找到lockKey对应对象，检查这个对象的版本，时间戳（要求上次修改时间必须在10分钟以内），锁对象（自己锁自己也是可以的，没锁也可以，算成功）
    *  如果锁符合条件，就要给这个代码块上锁，记录lastModify
    *  然后，这个很重要，要遍历lockInfo对象，找到所有其他的lockInfo.lockKey对应的结构体，如果也是自己上的锁，那么把锁去掉，一个人一个时间内，只能锁一个
    *  最后根据上述返回结果要求返回对应结果.
    *  注意：这里有个特殊的地方，锁互斥，要增加一种情况，如果有人在_$_whole上过锁（表示把整个文档锁起来了，而且还没超时），那么这个也是互斥的，也要返回锁失败
    */
    /**
	  *lockInfo是对象所信息，配套allData结构使用的，其结构如下：
	  *  {
	  *     fileName:{和allData的fileName对应结构
	  *        lastModify:最后一次修改的时间戳
	  *        lockKey:{//每一个锁的锁id值，其实就allData[fileName]下面的子对象的key例如allData.["c.file"].a这里a就是lockKey，_$_whole这个key是特殊的，表示全文件
	  *            lastModify:这个key上次申请的时间
	  *            version:这个key的版本号
	  *            lockuserid:锁这个对象的用户id，这里就是用sessionid表示，如果这个值不存在未null，就说明这个结构没有被锁，下面代码说明不再赘述了
	  *        }
	  *     }
	  *  }
	  */
	 
    //获取客户端数据中的文件名、锁KEY、版本号
    BreezeContext fileNameCtx =  BreezeContext.getObjectByPath("param.param.fileName",root);
    BreezeContext lockKeyCtx =  BreezeContext.getObjectByPath("param.param.lockKey",root);
    BreezeContext versionCtx =  BreezeContext.getObjectByPath("param.param.version",root);
     response.getWriter().println(this.allData);
      response.getWriter().println(this.lockInfo);
    //清除超时数据
    this.deleteTimeoutFile(System.currentTimeMillis());

    //保存全局锁信息
    BreezeContext currentWholeLockCtx=new BreezeContext();
    
    
     //获取文件信息
     BreezeContext fileData=this.getFile(fileNameCtx.toString(),lockKeyCtx.toString());
     BreezeContext currentFileCtx=fileData.getContextByPath("fileContent");
     BreezeContext currentLockFileDataCtx=fileData.getContextByPath("keyContent");
     int fileIndex= Integer.parseInt(fileData.getContextByPath("index").toString());
     BreezeContext isFileExist =fileData.getContextByPath("result");
     
     //获取锁信息
     BreezeContext lockData=this.getLock(fileNameCtx.toString(),lockKeyCtx.toString());
     BreezeContext currentLockCtx=lockData.getContextByPath("lockContent");
     BreezeContext currentLockInfoDataCtx=lockData.getContextByPath("keyContent");
     int lockInfoIndex= Integer.parseInt(lockData.getContextByPath("index").toString());
     BreezeContext isLockExist =lockData.getContextByPath("result"); 
   
    
    
     BreezeContext returnResult = new BreezeContext();
   
   if(!currentFileCtx.isNull() && !currentLockFileDataCtx.isNull())
   {
	     //判断文件是否存在
	    if(isFileExist.toString().equals("1"))
	    {
	     
	       //判断是否为全局锁
	       if(lockKeyCtx.toString().equals("_$_whole"))
	       {
	         
	         //判断是否存在全局锁
	          if(!currentLockInfoDataCtx.isNull())
	          {
	             //锁是否超时
	             if(System.currentTimeMillis()-Long.parseLong(currentLockInfoDataCtx.getContextByPath("lastModify").toString())>this.timeOut)
	             {
	              //全局锁超时
	              currentLockCtx=this.setLockKey(fileNameCtx.toString(),lockKeyCtx.toString(),lockInfoIndex,versionCtx.toString(),Long.toString(System.currentTimeMillis()),Long.toString(request.getSession().hashCode()));    
		  	      response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("申请全局锁时，存在全局锁超时，重新更新锁成功！")));
	             }
	             else
	             {
	               //判断用户是否一致
	                if(currentLockInfoDataCtx.getContextByPath("lockuserid").toString().equals(Long.toString(request.getSession().hashCode())))
					{ 
					     //判断版本是否一致
					     if(currentLockInfoDataCtx.getContextByPath("version").toString().equals(versionCtx.toString()))
					     {
					        //全局锁超时
				              currentLockCtx=this.setLockKey(fileNameCtx.toString(),lockKeyCtx.toString(),lockInfoIndex,versionCtx.toString(),Long.toString(System.currentTimeMillis()),Long.toString(request.getSession().hashCode()));    
					  	      response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("申请全局锁成功！")));
					     }
					     else
					     {
					       response.getWriter().println(this.returnResult(11,currentLockFileDataCtx,currentLockInfoDataCtx,new BreezeContext("申请全局锁时，版本不一致！")));
					     }
					}
					else
					{
					 response.getWriter().println(this.returnResult(12,null,null,new BreezeContext("申请全局锁时，用户不一致！")));
					}
	             }
	          }else
	          {
	              //不存在全局锁
	              currentLockCtx=this.setLockKey(fileNameCtx.toString(),lockKeyCtx.toString(),lockInfoIndex,versionCtx.toString(),Long.toString(System.currentTimeMillis()),Long.toString(request.getSession().hashCode()));    
		  	      response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("申请全局锁时，全局锁为空，申请成功！")));
	          }
	       }
	       else  //申请对象锁
	       {
	         
	          //获取全局锁信息
	          BreezeContext wholeLockData=this.isWholeLockExist(fileNameCtx.toString());
	          BreezeContext wholeLock=wholeLockData.getContextByPath("content");
	          BreezeContext wholeIndex=wholeLockData.getContextByPath("index");
	       
	          
	          //判断是否存在全局锁
	          if(!wholeLock.isNull())
	          {
	                
	               //锁是否超时
		             if(System.currentTimeMillis()-Long.parseLong(wholeLock.getContextByPath("lastModify").toString())>this.timeOut)
		             {
		                //清除全局锁
		                deleteLockKey(fileNameCtx.toString(),"_$_whole");
		                 
		                 //判断申请的对象锁是否存在
			             if(!currentLockInfoDataCtx.isNull())
			             {
				             //锁是否超时
				             if(System.currentTimeMillis()-Long.parseLong(currentLockInfoDataCtx.getContextByPath("lastModify").toString())>this.timeOut)
				             {
				              //对象锁超时
				              currentLockCtx=this.setLockKey(fileNameCtx.toString(),lockKeyCtx.toString(),lockInfoIndex,versionCtx.toString(),Long.toString(System.currentTimeMillis()),Long.toString(request.getSession().hashCode()));    
					  	      response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("申请对象锁时，存在全局锁，现存的对象锁超时！")));
				             }
				             else
				             {
				               //判断用户是否一致
				                if(currentLockInfoDataCtx.getContextByPath("lockuserid").toString().equals(Long.toString(request.getSession().hashCode())))
								{ 
								     //判断版本是否一致
								     if(currentLockInfoDataCtx.getContextByPath("version").toString().equals(versionCtx.toString()))
								     {
							
							              currentLockCtx=this.setLockKey(fileNameCtx.toString(),lockKeyCtx.toString(),lockInfoIndex,versionCtx.toString(),Long.toString(System.currentTimeMillis()),Long.toString(request.getSession().hashCode()));    
								  	      response.getWriter().println(this.returnResult(0,currentLockFileDataCtx,currentLockCtx,new BreezeContext("申请对象锁时，存在全局锁，版本一致申请成功！")));
								     }
								     else
								     {
								       response.getWriter().println(this.returnResult(11,currentLockFileDataCtx,currentLockInfoDataCtx,new BreezeContext("申请对象锁时，存在全局锁，版本不一致申请失败！")));
								     }
								}
								else
								{
								 response.getWriter().println(this.returnResult(12,null,null,new BreezeContext("申请对象锁时，存在全局锁，现存的对象用户不一致！")));
								}
				             }
			             }
			             else
			             {
			               //不存在添加对象锁
			              currentLockCtx=this.setLockKey(fileNameCtx.toString(),lockKeyCtx.toString(),lockInfoIndex,versionCtx.toString(),Long.toString(System.currentTimeMillis()),Long.toString(request.getSession().hashCode()));    
				  	      response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("申请对象锁时，存在全局锁，对象锁不存在，申请成功！")));
			             }
		             }
		             else
		             {
		                //判断用户是否一致
		                if(wholeLock.getContextByPath("lockuserid").toString().equals(Long.toString(request.getSession().hashCode())))
						{ 
						    
							 //清除全局锁
			                 deleteLockKey(fileNameCtx.toString(),"_$_whole");
			                 
			                 //判断申请的对象锁是否存在
				             if(!currentLockInfoDataCtx.isNull())
				             {
				                 
					             //锁是否超时
					             if(System.currentTimeMillis()-Long.parseLong(currentLockInfoDataCtx.getContextByPath("lastModify").toString())>this.timeOut)
					             {
					              //对象锁超时
					              currentLockCtx=this.setLockKey(fileNameCtx.toString(),lockKeyCtx.toString(),lockInfoIndex,versionCtx.toString(),Long.toString(System.currentTimeMillis()),Long.toString(request.getSession().hashCode()));    
						  	      response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("申请对象锁时，存在全局锁，现存的对象锁超时，申请成功！")));
					             }
					             else
					             {
					               //判断用户是否一致
					                if(currentLockInfoDataCtx.getContextByPath("lockuserid").toString().equals(Long.toString(request.getSession().hashCode())))
									{ 
									     //判断版本是否一致
									     if(currentLockInfoDataCtx.getContextByPath("version").toString().equals(versionCtx.toString()))
									     {
								
								              currentLockCtx=this.setLockKey(fileNameCtx.toString(),lockKeyCtx.toString(),lockInfoIndex,versionCtx.toString(),Long.toString(System.currentTimeMillis()),Long.toString(request.getSession().hashCode()));    
									  	      response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("申请对象锁时，存在全局锁，现存的对象锁用户版本一致，申请成功！")));
									     }
									     else
									     {
									       response.getWriter().println(this.returnResult(11,currentLockFileDataCtx,currentLockInfoDataCtx,new BreezeContext("申请对象锁时，存在全局锁，现存的对象锁用户版本不一致，申请失败！")));
									     }
									}
									else
									{
									 response.getWriter().println(this.returnResult(12,null,null,new BreezeContext("申请对象锁时，存在全局锁，现存的对象锁用户不一致，申请失败！")));
									}
					             }
				             }
				             else
				             {
				             
				               //不存在添加对象锁
				              currentLockCtx=this.setLockKey(fileNameCtx.toString(),lockKeyCtx.toString(),lockInfoIndex,versionCtx.toString(),Long.toString(System.currentTimeMillis()),Long.toString(request.getSession().hashCode()));    
		                       
					  	      response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("申请对象锁时，存在全局锁，对象锁为空，申请成功！")));
				             }
						}
						else
						{
						 response.getWriter().println(this.returnResult(12,null,null,new BreezeContext("申请对象锁时，存在全局锁用户不一致，申请失败！")));
						}
		             }
	          }else
	          {
	             
	             //判断申请的对象锁是否存在
	             if(!currentLockInfoDataCtx.isNull())
	             {
	                 
		             //锁是否超时
		             if(System.currentTimeMillis()-Long.parseLong(currentLockInfoDataCtx.getContextByPath("lastModify").toString())>this.timeOut)
		             {
		              //对象锁超时
		              currentLockCtx=this.setLockKey(fileNameCtx.toString(),lockKeyCtx.toString(),lockInfoIndex,versionCtx.toString(),Long.toString(System.currentTimeMillis()),Long.toString(request.getSession().hashCode()));    
			  	      response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("申请对象锁时，不存在全局锁，现存的对象锁超时，申请成功！")));
		             }
		             else
		             {
		               //判断用户是否一致
		                if(currentLockInfoDataCtx.getContextByPath("lockuserid").toString().equals(Long.toString(request.getSession().hashCode())))
						{ 
						     //判断版本是否一致
						     if(currentLockInfoDataCtx.getContextByPath("version").toString().equals(versionCtx.toString()))
						     {
					
					              currentLockCtx=this.setLockKey(fileNameCtx.toString(),lockKeyCtx.toString(),lockInfoIndex,versionCtx.toString(),Long.toString(System.currentTimeMillis()),Long.toString(request.getSession().hashCode()));    
						  	      response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("申请对象锁时，不存在全局锁，现存的对象锁用户版本一致，申请成功！")));
						     }
						     else
						     {
						       response.getWriter().println(this.returnResult(11,currentLockFileDataCtx,currentLockInfoDataCtx,new BreezeContext("申请对象锁时，不存在全局锁，现存的对象锁用户版本不一致，申请失败！")));
						     }
						}
						else
						{
						 response.getWriter().println(this.returnResult(12,null,null,new BreezeContext("申请对象锁时，不存在全局锁，现存的对象锁用户不一致，申请失败！")));
						}
		             }
	             }
	             else
	             {
	               //不存在添加对象锁
	              currentLockCtx=this.setLockKey(fileNameCtx.toString(),lockKeyCtx.toString(),lockInfoIndex,versionCtx.toString(),Long.toString(System.currentTimeMillis()),Long.toString(request.getSession().hashCode()));    
		  	      response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("申请对象锁时，不存在全局锁，且对象锁为空，申请成功！")));
	             }
	          }
	       }
	   
	    }else{
		  response.getWriter().println(this.returnResult(13,null,null,new BreezeContext("申请对象锁时，不存在全局锁，指定锁文件不存在，申请失败！")));	
	    }	
   }else{
		  response.getWriter().println(this.returnResult(13,null,null,new BreezeContext("申请失败，指定文件或文件对象不存在！")));	
   }
  
    


}
%>

<%
    //!处理类型是checkin情况
    if ("checkin".equals(operType)){
    /**
    * 参数:这个类型情况下的param的结构如下：
    * {
    *    fileName:文件名
    *    lockKey:要所的对象key，注意；如果要锁全局锁，这里填_$_whole
    *    content:{//这个key下对应的内容
    *    }
    *    version:当前这个要锁对象的版本号
    *    wholdVersion:完整大文件的版本
    * }
    */
    /**
    *  返回的结构如下：
    *  {
    *    code:结果码0表示成功；1表示提交成功，但是大版本不正确，这种情况其他部分会返回整个版本信息;11表示版本不对，不让提交;
    *                          12表示已经被其他人锁了，即操作时间过长，锁被释放了，不能提交;其他情况返回其他结果码
    *                          13表示指定文件不存在
    *    data:{//仅当结果码为0或1时，才返回数据
    *       content{//只有返回结果码为1的时候才会有数据
    *       },
    *       lockInfo{//如果是返回结果码为0，则返回对应新的版本号，包括全局版本号和局部版本号；如果结果码是1，对应的是整个这个文件的lockInfo内容
    *       }
    *    }
    *  }
    */
    /**
    *  处理逻辑：
    *  找到lockKey对应对象，检查这个对象的版本，版本必须和客户端版本一致，时间戳（如果是其他人锁的但超10分钟了，还是可以提交的），锁对象（自己锁自己也是可以的，没锁也可以，算成功）
    *  如果锁符合条件，就设置如提交的对象，同时要给这个代码块重新上锁，记录lastModify，同时局部锁的版本号加1
    *  比较全局锁，和这个锁是否一致，如果不一致，要返回全部数据。不管是否一致，全局锁都要加1，同时下发新版本号
    */
   
    //获取客户端数据中的文件名、锁KEY、版本号、全局版本号、文件内容
    BreezeContext fileNameCtx =  BreezeContext.getObjectByPath("param.param.fileName",root);
    BreezeContext lockKeyCtx =  BreezeContext.getObjectByPath("param.param.lockKey",root);
    BreezeContext versionCtx =  BreezeContext.getObjectByPath("param.param.version",root);
    BreezeContext wholdVersionCtx =  BreezeContext.getObjectByPath("param.param.wholdVersion",root);
    BreezeContext contentCtx =  BreezeContext.getObjectByPath("param.param.content",root);
    
    //清除超时数据
    this.deleteTimeoutFile(System.currentTimeMillis());
    
    //通过文件名，锁名获取文件信息
     BreezeContext fileData=this.getFile(fileNameCtx.toString(),lockKeyCtx.toString());
     BreezeContext currentFileCtx=fileData.getContextByPath("fileContent");
     BreezeContext currentLockFileDataCtx=fileData.getContextByPath("keyContent");
     int fileIndex= Integer.parseInt(fileData.getContextByPath("index").toString());
     BreezeContext isFileExist =fileData.getContextByPath("result");
   
    //通过文件名，锁名获取锁信息
    BreezeContext lockData=this.getLock(fileNameCtx.toString(),lockKeyCtx.toString());
    BreezeContext currentLockCtx=lockData.getContextByPath("lockContent");
    BreezeContext currentLockInfoDataCtx=lockData.getContextByPath("keyContent");
    int lockInfoIndex= Integer.parseInt(lockData.getContextByPath("index").toString());
    BreezeContext isLockExist =lockData.getContextByPath("result");
    BreezeContext lockWholeVersion=currentLockCtx.getContextByPath("version");
    

   
   if(!currentFileCtx.isNull() && !currentLockFileDataCtx.isNull())
   {
	     //判断文件是否存在
	    if(isFileExist.toString().equals("1"))
	    {
	     
	       //判断是否为全局锁
	       if(lockKeyCtx.toString().equals("_$_whole"))
	       {
	         
	         //判断是否存在全局锁
	          if(!currentLockInfoDataCtx.isNull())
	          {
	             //锁是否超时
	             if(System.currentTimeMillis()-Long.parseLong(currentLockInfoDataCtx.getContextByPath("lastModify").toString())>this.timeOut)
	             {
	              //全局锁超时
                           if(lockWholeVersion.toString().equals(wholdVersionCtx.toString()))
							{
 							 this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode()));  
                             response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("提交成功！")));		
							}
							else
							{
								BreezeContext returnFileLock=this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode())); 
								response.getWriter().println(this.returnResult(1,returnFileLock.getContextByPath("file"),returnFileLock.getContextByPath("lock"),new BreezeContext("大版本不一致，提交成功！")));
							} 
	             }
	             else
	             {
	               //判断用户是否一致
	                if(currentLockInfoDataCtx.getContextByPath("lockuserid").toString().equals(Long.toString(request.getSession().hashCode())))
					{ 
					     //判断版本是否一致
					     if(currentLockInfoDataCtx.getContextByPath("version").toString().equals(versionCtx.toString()))
					     {
					        //全局锁超时
                           if(lockWholeVersion.toString().equals(wholdVersionCtx.toString()))
							{
 							 this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode()));  
                             response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("提交成功！")));		
							}
							else
							{
								BreezeContext returnFileLock=this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode())); 
								response.getWriter().println(this.returnResult(1,returnFileLock.getContextByPath("file"),returnFileLock.getContextByPath("lock"),new BreezeContext("大版本不一致，提交成功！")));
							} 
					     }
					     else
					     {
					       response.getWriter().println(this.returnResult(11,currentLockFileDataCtx,currentLockInfoDataCtx,new BreezeContext("提交失败，版本不一致！")));
					     }
					}
					else
					{
					 response.getWriter().println(this.returnResult(12,null,null,new BreezeContext("提交失败，用户不一致！")));
					}
	             }
	          }else
	          {
	              //不存在全局锁
                           if(lockWholeVersion.toString().equals(wholdVersionCtx.toString()))
							{
 							 this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode()));  
                             response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("提交成功！")));		
							}
							else
							{
								BreezeContext returnFileLock=this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode())); 
								response.getWriter().println(this.returnResult(1,returnFileLock.getContextByPath("file"),returnFileLock.getContextByPath("lock"),new BreezeContext("大版本不一致，提交成功！")));
							} 
	          }
	       }
	       else  //申请对象锁
	       {
	         
	          //获取全局锁信息
	          BreezeContext wholeLockData=this.isWholeLockExist(fileNameCtx.toString());
	          BreezeContext wholeLock=wholeLockData.getContextByPath("content");
	          BreezeContext wholeIndex=wholeLockData.getContextByPath("index");
	       
	          
	          //判断是否存在全局锁
	          if(!wholeLock.isNull())
	          {
	                
	               //锁是否超时
		             if(System.currentTimeMillis()-Long.parseLong(wholeLock.getContextByPath("lastModify").toString())>this.timeOut)
		             {
		                //清除全局锁
		                deleteLockKey(fileNameCtx.toString(),"_$_whole");
		                 
		                 //判断申请的对象锁是否存在
			             if(!currentLockInfoDataCtx.isNull())
			             {
				             //锁是否超时
				             if(System.currentTimeMillis()-Long.parseLong(currentLockInfoDataCtx.getContextByPath("lastModify").toString())>this.timeOut)
				             {
				              //对象锁超时
	                           if(lockWholeVersion.toString().equals(wholdVersionCtx.toString()))
								{
	 							 this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode()));  
	                             response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("提交成功！")));		
								}
								else
								{
									BreezeContext returnFileLock=this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode())); 
									response.getWriter().println(this.returnResult(1,returnFileLock.getContextByPath("file"),returnFileLock.getContextByPath("lock"),new BreezeContext("大版本不一致，提交成功！")));
								} 
				             }
				             else
				             {
				               //判断用户是否一致
				                if(currentLockInfoDataCtx.getContextByPath("lockuserid").toString().equals(Long.toString(request.getSession().hashCode())))
								{ 
								     //判断版本是否一致
								     if(currentLockInfoDataCtx.getContextByPath("version").toString().equals(versionCtx.toString()))
								     {
							
			                           if(lockWholeVersion.toString().equals(wholdVersionCtx.toString()))
										{
			 							 this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode()));  
			                             response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("提交成功！")));		
										}
										else
										{
											BreezeContext returnFileLock=this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode())); 
											response.getWriter().println(this.returnResult(1,returnFileLock.getContextByPath("file"),returnFileLock.getContextByPath("lock"),new BreezeContext("大版本不一致，提交成功！")));
										} 
								     }
								     else
								     {
								       response.getWriter().println(this.returnResult(11,currentLockFileDataCtx,currentLockInfoDataCtx,new BreezeContext("提交失败，版本不一致！")));
								     }
								}
								else
								{
								 response.getWriter().println(this.returnResult(12,null,null,new BreezeContext("提交失败，用户不一致！")));
								}
				             }
			             }
			             else
			             {
			               //不存在添加对象锁
                           if(lockWholeVersion.toString().equals(wholdVersionCtx.toString()))
							{
 							 this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode()));  
                             response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("提交成功！")));		
							}
							else
							{
								BreezeContext returnFileLock=this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode())); 
								response.getWriter().println(this.returnResult(1,returnFileLock.getContextByPath("file"),returnFileLock.getContextByPath("lock"),new BreezeContext("大版本不一致，提交成功！")));
							} 
			             }
		             }
		             else
		             {
		                //判断用户是否一致
		                if(wholeLock.getContextByPath("lockuserid").toString().equals(Long.toString(request.getSession().hashCode())))
						{ 
						    
							 //清除自身全局锁
			                 deleteLockKey(fileNameCtx.toString(),"_$_whole");
			                 
			                 //判断申请的对象锁是否存在
				             if(!currentLockInfoDataCtx.isNull())
				             {
				                 
					             //锁是否超时
					             if(System.currentTimeMillis()-Long.parseLong(currentLockInfoDataCtx.getContextByPath("lastModify").toString())>this.timeOut)
					             {
					              //对象锁超时
		                           if(lockWholeVersion.toString().equals(wholdVersionCtx.toString()))
									{
		 							 this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode()));  
		                             response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("提交成功！")));		
									}
									else
									{
										BreezeContext returnFileLock=this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode())); 
										response.getWriter().println(this.returnResult(1,returnFileLock.getContextByPath("file"),returnFileLock.getContextByPath("lock"),new BreezeContext("大版本不一致，提交成功！")));
									} 
					             }
					             else
					             {
					               //判断用户是否一致
					                if(currentLockInfoDataCtx.getContextByPath("lockuserid").toString().equals(Long.toString(request.getSession().hashCode())))
									{ 
									     //判断版本是否一致
									     if(currentLockInfoDataCtx.getContextByPath("version").toString().equals(versionCtx.toString()))
									     {
				                           if(lockWholeVersion.toString().equals(wholdVersionCtx.toString()))
											{
				 							 this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode()));  
				                             response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("提交成功！")));		
											}
											else
											{
												BreezeContext returnFileLock=this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode())); 
												response.getWriter().println(this.returnResult(1,returnFileLock.getContextByPath("file"),returnFileLock.getContextByPath("lock"),new BreezeContext("大版本不一致，提交成功！")));
											} 									     
										}
									     else
									     {
									       response.getWriter().println(this.returnResult(11,currentLockFileDataCtx,currentLockInfoDataCtx,new BreezeContext("提交失败，版本不一致！")));
									     }
									}
									else
									{
									 response.getWriter().println(this.returnResult(12,null,null,new BreezeContext("提交失败，用户不一致！")));
									}
					             }
				             }
				             else
				             {
				             
				               //不存在添加对象锁
		                           if(lockWholeVersion.toString().equals(wholdVersionCtx.toString()))
									{
		 							 this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode()));  
		                             response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("提交成功！")));		
									}
									else
									{
										BreezeContext returnFileLock=this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode())); 
										response.getWriter().println(this.returnResult(1,returnFileLock.getContextByPath("file"),returnFileLock.getContextByPath("lock"),new BreezeContext("大版本不一致，提交成功！")));
									} 
				             }
						}
						else
						{
						 response.getWriter().println(this.returnResult(12,null,null,new BreezeContext("提交失败，用户不一致！")));
						}
		             }
	          }else
	          {
	             
	             //判断申请的对象锁是否存在
	             if(!currentLockInfoDataCtx.isNull())
	             {
	                 
		             //锁是否超时
		             if(System.currentTimeMillis()-Long.parseLong(currentLockInfoDataCtx.getContextByPath("lastModify").toString())>this.timeOut)
		             {
		              //对象锁超时
                           if(lockWholeVersion.toString().equals(wholdVersionCtx.toString()))
							{
 							 this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode()));  
                             response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("提交成功！")));		
							}
							else
							{
								BreezeContext returnFileLock=this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode())); 
								response.getWriter().println(this.returnResult(1,returnFileLock.getContextByPath("file"),returnFileLock.getContextByPath("lock"),new BreezeContext("大版本不一致，提交成功！")));
							} 
		             }
		             else
		             {
		               //判断用户是否一致
		                if(currentLockInfoDataCtx.getContextByPath("lockuserid").toString().equals(Long.toString(request.getSession().hashCode())))
						{ 
						     //判断版本是否一致
						     if(currentLockInfoDataCtx.getContextByPath("version").toString().equals(versionCtx.toString()))
						     {
					
	                           if(lockWholeVersion.toString().equals(wholdVersionCtx.toString()))
								{
	 							 this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode()));  
	                             response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("提交成功！")));		
								}
								else
								{
									BreezeContext returnFileLock=this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode())); 
									response.getWriter().println(this.returnResult(1,returnFileLock.getContextByPath("file"),returnFileLock.getContextByPath("lock"),new BreezeContext("大版本不一致，提交成功！")));
								} 
						     }
						     else
						     {
						       response.getWriter().println(this.returnResult(11,currentLockFileDataCtx,currentLockInfoDataCtx,new BreezeContext("提交失败，版本不一致！")));
						     }
						}
						else
						{
						 response.getWriter().println(this.returnResult(12,null,null,new BreezeContext("提交失败，用户不一致！")));
						}
		             }
	             }
	             else
	             {
	               //不存在添加对象锁
                           if(lockWholeVersion.toString().equals(wholdVersionCtx.toString()))
							{
 							 this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode()));  
                             response.getWriter().println(this.returnResult(0,null,null,new BreezeContext("提交成功！")));		
							}
							else
							{
								BreezeContext returnFileLock=this.commit(lockKeyCtx.toString(),contentCtx,fileNameCtx.toString(),System.currentTimeMillis(),Integer.parseInt(lockWholeVersion.toString()),Integer.parseInt(versionCtx.toString()),Long.toString(request.getSession().hashCode())); 
								response.getWriter().println(this.returnResult(1,returnFileLock.getContextByPath("file"),returnFileLock.getContextByPath("lock"),new BreezeContext("大版本不一致，提交成功！")));
							} 
	             }
	          }
	       }
	   
	    }else{
		  response.getWriter().println(this.returnResult(13,null,null,new BreezeContext("提交失败，指定文件不存在！")));	
	    }	
   }else{
		  response.getWriter().println(this.returnResult(13,null,null,new BreezeContext("提交失败，指定文件或文件对象不存在！")));	
   } 
}
%>