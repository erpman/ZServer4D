unit HPC_CliFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  CommunicationFramework,
  DoStatusIO, CoreClasses,
  CommunicationFramework_Client_CrossSocket,
  CommunicationFramework_Client_ICS, CommunicationFramework_Client_Indy,
  Cadencer, DataFrameEngine, CommunicationFrameworkDoubleTunnelIO_NoAuth;

type
  TDoubleTunnelClientForm = class(TForm)
    Memo1: TMemo;
    ConnectButton: TButton;
    HostEdit: TLabeledEdit;
    Timer1: TTimer;
    HelloWorldBtn: TButton;
    AsyncConnectButton: TButton;
    procedure ConnectButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure HelloWorldBtnClick(Sender: TObject);
    procedure AsyncConnectButtonClick(Sender: TObject);
  private
    { Private declarations }
    procedure DoStatusNear(AText: string; const ID: Integer);

    procedure cmd_ChangeCaption(Sender: TPeerClient; InData: TDataFrameEngine);
    procedure cmd_GetClientValue(Sender: TPeerClient; InData, OutData: TDataFrameEngine);
  public
    { Public declarations }
    RecvTunnel: TCommunicationFramework_Client_CrossSocket;
    SendTunnel: TCommunicationFramework_Client_CrossSocket;
    client    : TCommunicationFramework_DoubleTunnelClient_NoAuth;
  end;

var
  DoubleTunnelClientForm: TDoubleTunnelClientForm;

implementation

{$R *.dfm}


procedure TDoubleTunnelClientForm.DoStatusNear(AText: string; const ID: Integer);
begin
  Memo1.Lines.Add(AText);
end;

procedure TDoubleTunnelClientForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(self, DoStatusNear);

  RecvTunnel := TCommunicationFramework_Client_CrossSocket.Create;
  SendTunnel := TCommunicationFramework_Client_CrossSocket.Create;
  client := TCommunicationFramework_DoubleTunnelClient_NoAuth.Create(RecvTunnel, SendTunnel);

  client.RegisterCommand;

  // ע������ɷ����������ͨѶָ��
  client.RecvTunnel.RegisterDirectStream('ChangeCaption').OnExecute := cmd_ChangeCaption;
  client.RecvTunnel.RegisterStream('GetClientValue').OnExecute := cmd_GetClientValue;
end;

procedure TDoubleTunnelClientForm.FormDestroy(Sender: TObject);
begin
  DisposeObject(client);
  DeleteDoStatusHook(self);
end;

procedure TDoubleTunnelClientForm.HelloWorldBtnClick(Sender: TObject);
var
  SendDe, ResultDE: TDataFrameEngine;
begin
  // �첽��ʽ���ͣ����ҽ���Streamָ�������proc�ص�����
  SendDe := TDataFrameEngine.Create;
  SendDe.WriteString('123456');
  client.SendTunnel.SendStreamCmdP('helloWorld_Stream_Result', SendDe,
    procedure(Sender: TPeerClient; ResultData: TDataFrameEngine)
    begin
      if ResultData.Count > 0 then
          DoStatus('server response:%s', [ResultData.Reader.ReadString]);
    end);
  DisposeObject([SendDe]);

  // ������ʽ���ͣ����ҽ���Streamָ��
  SendDe := TDataFrameEngine.Create;
  ResultDE := TDataFrameEngine.Create;
  SendDe.WriteString('123456');
  client.SendTunnel.WaitSendStreamCmd('helloWorld_Stream_Result', SendDe, ResultDE, 5000);
  if ResultDE.Count > 0 then
      DoStatus('server response:%s', [ResultDE.Reader.ReadString]);
  DisposeObject([SendDe, ResultDE]);
end;

procedure TDoubleTunnelClientForm.Timer1Timer(Sender: TObject);
begin
  client.Progress;
end;

procedure TDoubleTunnelClientForm.cmd_ChangeCaption(Sender: TPeerClient; InData: TDataFrameEngine);
begin
  Caption := InData.Reader.ReadString;
end;

procedure TDoubleTunnelClientForm.cmd_GetClientValue(Sender: TPeerClient; InData, OutData: TDataFrameEngine);
begin
  OutData.WriteString('getclientvalue:abc');
end;

procedure TDoubleTunnelClientForm.ConnectButtonClick(Sender: TObject);
begin
  // ����1������ʽ����
  SendTunnel.Connect(HostEdit.Text, 9815);
  RecvTunnel.Connect(HostEdit.Text, 9816);

  // ���˫ͨ���Ƿ��Ѿ��ɹ����ӣ�ȷ������˶ԳƼ��ܵȵȳ�ʼ������
  while (not client.RemoteInited) and (client.Connected) do
    begin
      TThread.Sleep(10);
      client.Progress;
    end;

  if client.Connected then
    begin
      // �첽��ʽ�ϲ�����ͨ��
      client.TunnelLinkP(
        procedure(const State: Boolean)
        begin
          if State then
            begin
              // ˫ͨ�����ӳɹ�
              DoStatus('double tunnel link success!');
            end;
        end);
      // ͬ����ʽ�ϲ�����ͨ��
      // if client.TunnelLink then
      // begin
      // // ˫ͨ�����ӳɹ�
      // end;
    end;
end;

procedure TDoubleTunnelClientForm.AsyncConnectButtonClick(Sender: TObject);
begin
  // ����2���첽ʽ˫ͨ������
  client.AsyncConnectP(HostEdit.Text, 9816, 9815,
    procedure(const cState: Boolean)
    begin
      if cState then
        // �첽��ʽ�ϲ�����ͨ��
          client.TunnelLinkP(
          procedure(const tState: Boolean)
          begin
            if tState then
              begin
                // ˫ͨ�����ӳɹ�
                DoStatus('double tunnel link success!');
              end;
          end);
      // ͬ����ʽ�ϲ�����ͨ��
      // if client.TunnelLink then
      // begin
      // // ˫ͨ�����ӳɹ�
      // end;
    end);
end;

end.