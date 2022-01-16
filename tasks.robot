*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Variables ***
${DIR_RECEIPT}    Receipts

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${url}=    Get file location from vault
    Request todays date
    ${orders}=    Get orders    ${url}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    ${zipfile}=    Create a ZIP file of the receipts
    Success dialog    ${zipfile}

*** Keywords ***
[Documentation] Keywords for the dialog messages

Request todays date
    Add heading    Date
    Add text    Please provide today's date.
    Add Date Input    todaydate    label=Today's Date
    ${result}=    Run dialog
    [Return]    ${result.todaydate}

Success dialog
    [Arguments]    ${zipfile}
    Add icon    success
    Add heading    Your orders have been successfully processed!
    Add text    Your order receipts have been saved here: ${zipfile}
    Run dialog    title=Success

*** Keywords ***
Get file location from vault
    ${secret}=    Get Secret    orders
    [Return]    ${secret}

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    [Arguments]    ${url}
    Download    ${url}[vaultfileurl]    overwrite=${TRUE}
    ${orders}=    Read table from CSV    orders.csv
    [Return]    ${orders}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${orders}
    Select From List By Index    id:head    ${orders}[Head]
    Select Radio Button    body    ${orders}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${orders}[Legs]
    Input Text    address    ${orders}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Wait Until Keyword Succeeds    10x    1sec    Click order button

Click order button
    Click Button    order
    Element Should Be Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${row}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${receipt_no}=    Get Text    xpath://*[@id="receipt"]/p[1]
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}${DIR_RECEIPT}${/}${row}.pdf
    [Return]    ${OUTPUT_DIR}${/}${DIR_RECEIPT}${/}${row}.pdf

Take a screenshot of the robot
    [Arguments]    ${row}
    Set Screenshot Directory    ${OUTPUT_DIR}${/}Screenshot
    Capture Element Screenshot    id:robot-preview-image    ${row}.png
    [Return]    ${OUTPUT_DIR}${/}Screenshot${/}${row}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List
    ...    ${pdf}
    ...    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}

Go to order another robot
    Click Button    id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}${DIR_RECEIPT}    orderreceipt.zip
    [Return]    ${OUTPUT_DIR}${/}${DIR_RECEIPT}${/}orderreceipt.zip
