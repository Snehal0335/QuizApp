WSDL Database connection server code 

  package server;

import java.sql.*;
import javax.jws.WebService;
import javax.jws.WebMethod;

@WebService(serviceName = "Curry_server")
public class Curry_server {

    @WebMethod
    public double rupeeToDollar(double rupee) throws Exception {

        Class.forName("com.mysql.cj.jdbc.Driver");

        Connection con = DriverManager.getConnection(
        "jdbc:mysql://localhost:3306/currency_db","root","");

        PreparedStatement ps = con.prepareStatement(
        "SELECT rate FROM currency WHERE name='Dollar'");

        ResultSet rs = ps.executeQuery();
        rs.next();

        double rate = rs.getDouble("rate");

        return rupee * rate;
    }

    @WebMethod
    public double rupeeToEuro(double rupee) throws Exception {

        Class.forName("com.mysql.cj.jdbc.Driver");

        Connection con = DriverManager.getConnection(
        "jdbc:mysql://localhost:3306/currency_db","root","");

        PreparedStatement ps = con.prepareStatement(
        "SELECT rate FROM currency WHERE name='Euro'");

        ResultSet rs = ps.executeQuery();
        rs.next();

        double rate = rs.getDouble("rate");

        return rupee * rate;
    }
}
